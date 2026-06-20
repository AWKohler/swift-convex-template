// ─────────────────────────────────────────────────────────────────
// ItemsStore.swift — Observable store backed by a Convex subscription
//
// This is the Swift analog of a React component calling
// `useQuery(api.items.list)` + `useMutation(api.items.add)`:
//   • `start()` opens a live subscription to the `items:list` query and
//     republishes every update into `items` — the UI rebuilds reactively.
//   • `add(text:)` calls the `items:add` mutation; the subscription then
//     pushes the new list automatically (no manual refetch).
//
// @MainActor because it mutates @Observable state consumed by SwiftUI.
// ─────────────────────────────────────────────────────────────────

import Foundation
import ConvexMobile

@MainActor
@Observable
final class ItemsStore {
    private(set) var items: [Item] = []
    private(set) var isLoading: Bool = true
    private(set) var lastError: String?

    private var subscription: Task<Void, Never>?

    /// Begin listening to the `items:list` query. Idempotent.
    func start() {
        subscription?.cancel()
        isLoading = true
        subscription = Task { [weak self] in
            let stream = Convex.shared
                .subscribe(to: ConvexAPI.Items.list, yielding: [Item].self)
                .values
            do {
                for try await latest in stream {
                    self?.items = latest
                    self?.isLoading = false
                    self?.lastError = nil
                }
            } catch {
                self?.isLoading = false
                self?.lastError = String(describing: error)
            }
        }
    }

    /// Insert a new item. The live subscription delivers the updated list.
    func add(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try await Convex.shared.mutation(ConvexAPI.Items.add, with: ["text": trimmed])
        } catch {
            lastError = String(describing: error)
        }
    }

    func stop() {
        subscription?.cancel()
        subscription = nil
    }
}
