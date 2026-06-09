// ─────────────────────────────────────────────────────────────────
// AuthStore.swift — Observable mirror of the Convex auth state
//
// The Swift analog of the web template's <Authenticated>/<Unauthenticated>
// split. It subscribes to `ConvexClientWithAuth.authState` and republishes a
// simple `State` enum the UI gates on, plus `signIn()` / `signOut()` /
// `restore()` actions.
//
// When auth is NOT enabled for the project, `state` is permanently `.signedIn`
// so the rest of the app renders normally (the gate is a no-op).
// ─────────────────────────────────────────────────────────────────

import Foundation
import Combine
import ConvexMobile

@MainActor
@Observable
final class AuthStore {
    enum State {
        case loading
        case signedOut
        case signedIn
    }

    private(set) var state: State
    private(set) var lastError: String?

    @ObservationIgnored private var cancellable: AnyCancellable?

    init() {
        if let auth = Convex.auth {
            // Start in `.loading`; `restore()` (called on launch) resolves it.
            state = .loading
            cancellable = auth.authState
                .receive(on: DispatchQueue.main)
                .sink { [weak self] authState in
                    switch authState {
                    case .authenticated:   self?.state = .signedIn
                    case .unauthenticated: self?.state = .signedOut
                    case .loading:         self?.state = .loading
                    }
                }
        } else {
            // No auth configured — the gate is transparent.
            state = .signedIn
        }
    }

    /// Silent re-auth on launch: exchange the stored refresh token for a fresh
    /// JWT without opening the browser. No-op (→ `.signedOut`) if there is no
    /// stored session.
    func restore() async {
        guard let auth = Convex.auth else { return }
        _ = await auth.loginFromCache()
    }

    /// Opens the in-app browser sign-in flow.
    func signIn() async {
        guard let auth = Convex.auth else { return }
        lastError = nil
        let result = await auth.login()
        if case .failure(let error) = result {
            lastError = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
        }
    }

    func signOut() async {
        await Convex.auth?.logout()
    }
}
