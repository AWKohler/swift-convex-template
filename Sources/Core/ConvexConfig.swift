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

    /// True when auth has been configured for this project (`setupAuth`).
    /// Botflow flips this to `true` when it regenerates this file after auth
    /// setup; while `false` the app runs un-authenticated and the auth
    /// scaffolding stays inert. DO NOT EDIT — it is platform-managed.
    static let authEnabled = false

    /// True when the URL is still the committed placeholder (no backend wired yet).
    static var isPlaceholder: Bool { url.contains("placeholder") }

    /// The deployment's HTTP-actions origin (`*.convex.site`), derived from
    /// `url` (`*.convex.cloud`). This is where the in-app-browser sign-in page
    /// and the Convex Auth HTTP routes live.
    static var siteURL: String {
        url.replacingOccurrences(of: ".convex.cloud", with: ".convex.site")
    }
}
