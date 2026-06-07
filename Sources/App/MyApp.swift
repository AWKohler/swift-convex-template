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

    init() {
        // Enables the Botflow IDE's device-orientation toggle while previewing
        // in the iOS Simulator. Compiled out of real-device / App Store builds.
        #if targetEnvironment(simulator)
        BotflowPreviewOrientation.start()
        #endif
    }

    var body: some Scene {
        WindowGroup {
            // ── Botflow: swap ContentView for your root view here ──
            ContentView()
            // ───────────────────────────────────────────────────────
        }
    }
}

// ─────────────────────────────────────────────────────────────────
// Botflow preview support — DO NOT ship-block on this.
//
// While the app runs inside the iOS Simulator under Botflow's live
// preview, the IDE's orientation toggle posts a Darwin notification
// that this observer turns into a `requestGeometryUpdate(...)` call,
// rotating the app the same way real hardware would. The whole block
// is wrapped in `#if targetEnvironment(simulator)`, so it does not
// exist in device or App Store builds — zero production footprint.
// ─────────────────────────────────────────────────────────────────
#if targetEnvironment(simulator)
import UIKit

enum BotflowPreviewOrientation {
    // Set once from MyApp.init() on the main actor; the opt-out is safe.
    nonisolated(unsafe) private static var started = false

    static func start() {
        guard !started else { return }
        started = true
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let names = [
            "io.botflow.orient.portrait",
            "io.botflow.orient.portraitupsidedown",
            "io.botflow.orient.landscape",       // == landscapeRight
            "io.botflow.orient.landscaperight",
            "io.botflow.orient.landscapeleft",
        ]
        for name in names {
            CFNotificationCenterAddObserver(
                center, nil,
                { _, _, cfName, _, _ in
                    BotflowPreviewOrientation.handle((cfName?.rawValue as String?) ?? "")
                },
                name as CFString, nil, .deliverImmediately)
        }
    }

    private static func handle(_ name: String) {
        let mask: UIInterfaceOrientationMask
        switch name {
        case "io.botflow.orient.landscape", "io.botflow.orient.landscaperight":
            mask = .landscapeRight
        case "io.botflow.orient.landscapeleft":
            mask = .landscapeLeft
        case "io.botflow.orient.portraitupsidedown":
            mask = .portraitUpsideDown
        default:
            mask = .portrait
        }
        Task { @MainActor in
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
            scene?.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
        }
    }
}
#endif
