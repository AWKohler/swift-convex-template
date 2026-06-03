// ─────────────────────────────────────────────────────────────────
// ConvexClient+Shared.swift — Shared Convex client
//
// One process-wide ConvexClient, built from the platform-injected
// deployment URL in ConvexConfig. Views/stores subscribe to queries and
// call mutations/actions through `Convex.shared`.
//
// This is the Swift equivalent of the web template's ConvexProvider /
// `useConvex()` — a single client that owns the sync-engine connection.
//
// Auth note: this template ships UN-authenticated (v1). To add auth
// later, swap `ConvexClient` for `ConvexClientWithAuth` with an
// AuthProvider (e.g. Clerk or Auth0) — see the README.
// ─────────────────────────────────────────────────────────────────

import Foundation
import ConvexMobile

enum Convex {
    /// Shared client wired to this project's Convex deployment.
    ///
    /// `nonisolated(unsafe)` is correct here under Swift 6 strict concurrency:
    /// ConvexClient is not marked Sendable, but it is internally thread-safe
    /// (it wraps the Convex Rust client, which manages its own synchronization).
    /// A single shared instance is the intended usage.
    nonisolated(unsafe) static let shared = ConvexClient(deploymentUrl: ConvexConfig.url)
}
