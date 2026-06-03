// ─────────────────────────────────────────────────────────────────
// MyApp.swift — Application entry point
//
// This template uses Convex as its backend AND its data layer. There is
// deliberately NO SwiftData here: the Convex sync engine is the single
// source of truth, delivering live query results over the network. A
// local ModelContainer would be a second, competing source of truth —
// so we don't have one.
//
// Botflow injection points:
//   • Insert additional Scene types (e.g. DocumentGroup) before the
//     closing brace of `var body`.
//   • Place app-wide environment objects on WindowGroup via
//     `.environment(myObject)`.
// ─────────────────────────────────────────────────────────────────

import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            // ── Botflow: swap ContentView for your root view here ──
            ContentView()
            // ───────────────────────────────────────────────────────
        }
    }
}
