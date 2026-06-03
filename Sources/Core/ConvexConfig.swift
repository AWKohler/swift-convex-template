// ─────────────────────────────────────────────────────────────────
// ConvexConfig.swift — Convex deployment URL (PLATFORM-MANAGED)
//
// ⚠️  DO NOT EDIT BY HAND.
//
// Botflow overwrites this file at preview/build time with the project's
// real Convex deployment URL (the platform-managed or bring-your-own
// deployment). It is the Swift analog of `import.meta.env.VITE_CONVEX_URL`
// in the web template.
//
// The value below is a placeholder so the project compiles standalone
// (e.g. `make build` locally before a deployment exists). At runtime in
// Botflow it is always replaced with the live `*.convex.cloud` URL.
// ─────────────────────────────────────────────────────────────────

import Foundation

enum ConvexConfig {
    /// The Convex deployment URL. Replaced by Botflow; placeholder otherwise.
    static let url = "https://placeholder.convex.cloud"

    /// True when the URL is still the committed placeholder (no backend wired yet).
    static var isPlaceholder: Bool { url.contains("placeholder") }
}
