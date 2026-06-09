// ─────────────────────────────────────────────────────────────────
// ConvexClient+Shared.swift — Shared Convex client
//
// One process-wide client, built from the platform-injected deployment URL
// in ConvexConfig. Views/stores subscribe to queries and call mutations/
// actions through `Convex.shared`.
//
// This is the Swift equivalent of the web template's ConvexProvider /
// `useConvex()` — a single client that owns the sync-engine connection.
//
// Auth: when Botflow has run `setupAuth` for this project, `ConvexConfig
// .authEnabled` is `true` and `shared` is a `ConvexClientWithAuth` driven by
// `BotflowAuthProvider` (Convex Auth via an in-app browser). Otherwise it is a
// plain `ConvexClient` and the app runs un-authenticated. Either way `shared`
// serves queries/mutations; use `Convex.auth` for login/logout/authState.
// ─────────────────────────────────────────────────────────────────

import Foundation
import ConvexMobile

enum Convex {
    /// The process-wide client. `ConvexClientWithAuth` (a `ConvexClient`
    /// subclass) when auth is enabled, else a plain `ConvexClient`.
    ///
    /// `nonisolated(unsafe)` matches the SDK's threading model: the client wraps
    /// the Convex Rust client, which manages its own synchronization, so a single
    /// shared instance is the intended usage and is safe to call from any context.
    nonisolated(unsafe) static let shared: ConvexClient = {
        guard ConvexConfig.authEnabled else {
            return ConvexClient(deploymentUrl: ConvexConfig.url)
        }
        return ConvexClientWithAuth(
            deploymentUrl: ConvexConfig.url,
            authProvider: BotflowAuthProvider()
        )
    }()

    /// The auth-capable client — non-nil only when auth is enabled. Use it for
    /// `login()` / `logout()` / `authState`. Same instance as `shared`.
    nonisolated(unsafe) static let auth: ConvexClientWithAuth<AuthCredentials>? =
        shared as? ConvexClientWithAuth<AuthCredentials>
}
