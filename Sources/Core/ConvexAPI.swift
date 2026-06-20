// ─────────────────────────────────────────────────────────────────
// ConvexAPI.swift — Convex function-name constants (PLATFORM-MANAGED)
//
// ⚠️  DO NOT EDIT BY HAND.
//
// Botflow REGENERATES this file from the deployed backend on every
// `convexDeploy`, one nested enum per backend module, one constant per
// public function. It is the Swift analog of the web template's
// `convex/_generated/api` — the only safe way to reference a Convex
// function from Swift.
//
// Convex function names are unchecked strings at compile time, so ALWAYS
// call through these constants — never a raw "file:function" literal:
//
//     Convex.shared.subscribe(to: ConvexAPI.Items.list, yielding: [Item].self)
//     try await Convex.shared.mutation(ConvexAPI.Items.add, with: ["text": text])
//
// A renamed or deleted backend function then breaks the BUILD (after the
// next deploy regenerates this file) instead of throwing at runtime.
//
// Workflow when adding/renaming backend functions:
//   1. Edit /convex (schema + functions).
//   2. Deploy the backend — this file regenerates with the new constants.
//   3. Only then write Swift code referencing them.
// ─────────────────────────────────────────────────────────────────

import Foundation

enum ConvexAPI {
    /// convex/items.ts
    enum Items {
        static let list = "items:list"
        static let add = "items:add"
    }
}
