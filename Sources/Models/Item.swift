// ─────────────────────────────────────────────────────────────────
// Item.swift — Baseline Convex-backed model
//
// Plain Decodable/Identifiable VALUE type — NOT a SwiftData @Model.
// Convex documents arrive as JSON and decode into structs like this one;
// the Convex sync engine (not a local ModelContainer) is the source of
// truth. This mirrors how the web template types its `useQuery` results.
//
// Keep these fields in sync with `convex/schema.ts` BY HAND — there is no
// Swift codegen from the Convex schema (unlike the web `_generated` API).
//
// Numeric fields: Convex encodes numbers specially. Use the ConvexMobile
// property wrappers when you add them, e.g.:
//     @ConvexInt   var count: Int
//     @ConvexFloat var score: Double
// ─────────────────────────────────────────────────────────────────

import Foundation

struct Item: Decodable, Identifiable {
    /// Convex document id (`_id`). Stable + unique → drives SwiftUI identity.
    let id: String
    /// User-entered text. Matches the `text` field in convex/schema.ts.
    let text: String

    private enum CodingKeys: String, CodingKey {
        case id = "_id"
        case text
    }
}
