import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

/**
 * Live list of items, newest first.
 * The Swift client subscribes to "items:list" and receives a new array
 * every time the underlying data changes (Convex sync engine).
 */
export const list = query({
  args: {},
  handler: async (ctx) => {
    return await ctx.db.query("items").order("desc").collect();
  },
});

/**
 * Insert a new item. Called from Swift as the "items:add" mutation.
 * Any open "items:list" subscription updates automatically afterwards.
 */
export const add = mutation({
  args: { text: v.string() },
  handler: async (ctx, { text }) => {
    await ctx.db.insert("items", { text });
  },
});
