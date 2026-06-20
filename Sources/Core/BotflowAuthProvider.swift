// ─────────────────────────────────────────────────────────────────
// BotflowAuthProvider.swift — Convex Auth via an in-app browser
//
// This is the Swift port of the web template's Convex Auth flow. Instead of
// a native sign-in form, the app opens the SAME Convex Auth password flow the
// web projects use, hosted as a page on this deployment's own *.convex.site
// origin, inside an `ASWebAuthenticationSession`. The page completes sign-in
// server-side and redirects back to `botflowauth://auth-callback#token=…&
// refresh=…`; we capture those tokens and hand the JWT to the Convex Swift SDK.
//
// It conforms to ConvexMobile's `AuthProvider`, so `ConvexClientWithAuth`
// drives it:
//   • login()         — first sign-in (opens the browser).
//   • loginFromCache() — silent re-auth / refresh. The SDK calls this whenever
//                        it needs a fresh JWT, so this is where we exchange the
//                        stored refresh token for a new one via the same
//                        `auth:signIn` action the web client uses.
//   • extractIdToken() — pull the JWT out of the credentials.
//
// Only the refresh token is persisted (Keychain). The JWT is short-lived and
// always re-derived. There is no Convex-Auth-specific native UI here at all —
// the hosted web page IS the form, which is exactly why the backend
// (`@convex-dev/auth`) carries over from the web template unchanged.
// ─────────────────────────────────────────────────────────────────

import Foundation
import AuthenticationServices
import UIKit
import ConvexMobile

/// Credentials returned by sign-in and by every refresh. This is the
/// `AuthProvider`'s associated type `T`; the SDK reads `token` (the JWT) from it.
struct AuthCredentials: Sendable {
    /// Short-lived JWT (the Convex ID token) used to authenticate requests.
    let token: String
    /// Long-lived refresh token. Rotates on every refresh — always persist the
    /// latest one.
    let refreshToken: String
}

enum AuthError: LocalizedError {
    case notConfigured
    case noStoredSession
    case cancelled
    case badCallback
    case sessionExpired
    case refreshFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:   return "No Convex deployment is configured yet."
        case .noStoredSession: return "Not signed in."
        case .cancelled:       return "Sign-in was cancelled."
        case .badCallback:     return "Sign-in returned an unexpected response."
        case .sessionExpired:  return "Your session expired. Please sign in again."
        case .refreshFailed(let m): return "Could not refresh session: \(m)"
        }
    }
}

@MainActor
final class BotflowAuthProvider: NSObject, AuthProvider {
    typealias T = AuthCredentials

    /// Custom scheme the sign-in page redirects to. `ASWebAuthenticationSession`
    /// intercepts this scheme internally — it does NOT need to be registered in
    /// Info.plist (CFBundleURLSchemes), so the template needs no project.yml change.
    private let callbackScheme = "botflowauth"

    /// Retains the in-flight session so it isn't deallocated mid-flow.
    private var session: ASWebAuthenticationSession?

    /// Nonisolated so the shared client (a nonisolated global) can construct the
    /// provider. The instance's mutable state and UI work stay main-actor isolated.
    nonisolated override init() {
        super.init()
    }

    // MARK: AuthProvider

    func login(onIdToken: @Sendable @escaping (String?) -> Void) async throws -> AuthCredentials {
        let creds = try await presentSignIn()
        Keychain.save(refreshToken: creds.refreshToken)
        onIdToken(creds.token)
        return creds
    }

    func loginFromCache(onIdToken: @Sendable @escaping (String?) -> Void) async throws -> AuthCredentials {
        guard let refreshToken = Keychain.loadRefreshToken() else {
            throw AuthError.noStoredSession
        }
        do {
            let creds = try await refresh(using: refreshToken)
            Keychain.save(refreshToken: creds.refreshToken)
            onIdToken(creds.token)
            return creds
        } catch AuthError.sessionExpired {
            // The server definitively rejected the refresh token — clear it so we
            // don't loop, and surface as unauthenticated. (Transient network
            // errors fall through WITHOUT clearing, so a blip won't sign the user out.)
            Keychain.clear()
            onIdToken(nil)
            throw AuthError.sessionExpired
        }
    }

    func logout() async throws {
        Keychain.clear()
    }

    nonisolated func extractIdToken(from authResult: AuthCredentials) -> String {
        authResult.token
    }

    // MARK: Sign-in (in-app browser)

    private func presentSignIn() async throws -> AuthCredentials {
        guard !ConvexConfig.isPlaceholder else { throw AuthError.notConfigured }

        var comps = URLComponents(string: ConvexConfig.siteURL + "/auth/signin")
        comps?.queryItems = [
            URLQueryItem(name: "redirect", value: "\(callbackScheme)://auth-callback")
        ]
        guard let url = comps?.url else { throw AuthError.notConfigured }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { callbackURL, error in
                if let error {
                    if let asError = error as? ASWebAuthenticationSessionError,
                       asError.code == .canceledLogin {
                        continuation.resume(throwing: AuthError.cancelled)
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let callbackURL, let creds = Self.parse(callbackURL) else {
                    continuation.resume(throwing: AuthError.badCallback)
                    return
                }
                continuation.resume(returning: creds)
            }
            session.presentationContextProvider = self
            // Reuse the system cookie store so a returning user isn't forced to
            // retype credentials in the browser.
            session.prefersEphemeralWebBrowserSession = false
            self.session = session
            session.start()
        }
    }

    /// Parse `botflowauth://auth-callback#token=…&refresh=…`. Tokens travel in the
    /// fragment so they never appear in server logs or the Referer header.
    private static func parse(_ url: URL) -> AuthCredentials? {
        guard let fragment = URLComponents(url: url, resolvingAgainstBaseURL: false)?.fragment else {
            return nil
        }
        var fields: [String: String] = [:]
        for pair in fragment.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
            guard kv.count == 2 else { continue }
            let value = String(kv[1]).removingPercentEncoding ?? String(kv[1])
            fields[String(kv[0])] = value
        }
        guard let token = fields["token"], let refresh = fields["refresh"],
              !token.isEmpty, !refresh.isEmpty else { return nil }
        return AuthCredentials(token: token, refreshToken: refresh)
    }

    // MARK: Refresh

    /// Exchange a refresh token for a fresh `{ token, refreshToken }` by calling
    /// the same `auth:signIn` action the web client uses, over Convex's HTTP API
    /// (one-shot — no second websocket). `@convex-dev/auth` rotates refresh tokens.
    private func refresh(using refreshToken: String) async throws -> AuthCredentials {
        guard !ConvexConfig.isPlaceholder, let endpoint = URL(string: ConvexConfig.url + "/api/action") else {
            throw AuthError.notConfigured
        }
        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "path": "auth:signIn",
            "args": ["refreshToken": refreshToken],
            "format": "json",
        ])

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw AuthError.refreshFailed("No HTTP response")
        }
        guard http.statusCode == 200 else {
            // 4xx/5xx from the function API is a transport-level failure, not a
            // definitive session rejection — don't clear the stored token.
            throw AuthError.refreshFailed("HTTP \(http.statusCode)")
        }
        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AuthError.refreshFailed("Malformed response")
        }
        if let status = root["status"] as? String, status != "success" {
            // The action ran and rejected the token → session is over.
            throw AuthError.sessionExpired
        }
        guard let value = root["value"] as? [String: Any],
              let tokens = value["tokens"] as? [String: Any],
              let token = tokens["token"] as? String,
              let newRefresh = tokens["refreshToken"] as? String
        else {
            // `tokens` is null when the refresh token is invalid/expired.
            throw AuthError.sessionExpired
        }
        return AuthCredentials(token: token, refreshToken: newRefresh)
    }
}

// MARK: Presentation anchor

extension BotflowAuthProvider: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(
        for session: ASWebAuthenticationSession
    ) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scenes = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
            let window = scenes
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
                ?? scenes.first?.windows.first
            return window ?? ASPresentationAnchor()
        }
    }
}
