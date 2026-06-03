import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

/**
 * Convex schema — the single source of truth for this app's data.
 *
 * This is IDENTICAL in shape to the web template's backend: the same
 * TypeScript functions deploy through the same Botflow pipeline. The only
 * difference is the client — a Swift app (ConvexMobile) instead of React.
 *
 * Keep Swift `Decodable` structs (e.g. Sources/Models/Item.swift) in sync
 * with the tables defined here.
 */
export default defineSchema({
  items: defineTable({
    text: v.string(),
  }),
});
