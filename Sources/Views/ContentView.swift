// ─────────────────────────────────────────────────────────────────
// ContentView.swift — Botflow welcome + live Convex demo
//
// Proves the backend is wired end-to-end: it subscribes to the
// `items:list` Convex query and writes via the `items:add` mutation.
// Add an item on one device and watch it appear live — that's the
// Convex sync engine, the same reactivity the web template gets from
// `useQuery`.
//
// Botflow replaces this view (or the whole file) once the user's first
// prompt produces a real UI.
// ─────────────────────────────────────────────────────────────────

import SwiftUI

// Root view. When auth is enabled (`setupAuth` has run) it gates the app behind
// the Convex auth state; otherwise it shows the demo directly.
struct ContentView: View {
    @State private var auth = AuthStore()

    var body: some View {
        Group {
            if !ConvexConfig.authEnabled {
                DemoFeed(auth: nil)
            } else {
                switch auth.state {
                case .loading:   AuthLoadingView()
                case .signedOut: SignInView(auth: auth)
                case .signedIn:  DemoFeed(auth: auth)
                }
            }
        }
        .task {
            // Silent refresh-token re-auth on launch (no browser).
            if ConvexConfig.authEnabled { await auth.restore() }
        }
    }
}

private struct AuthLoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ProgressView().tint(.white)
        }
    }
}

struct DemoFeed: View {
    /// Non-nil when auth is enabled — drives the Sign-out affordance.
    var auth: AuthStore?

    @State private var store = ItemsStore()
    @State private var draft: String = ""
    @State private var heroVisible = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 0) {
                header
                    .padding(.top, 60)
                    .padding(.horizontal, 28)

                content
                    .padding(.top, 28)

                composer
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            }

            if let auth {
                signOutBar(auth)
            }
        }
        .task { store.start() }
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.3)) { heroVisible = true }
        }
    }

    // ── Sign out ─────────────────────────────────────────────────

    private func signOutBar(_ auth: AuthStore) -> some View {
        VStack {
            HStack {
                Spacer()
                Button("Sign out") {
                    Task { await auth.signOut() }
                }
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.55))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            }
            .padding(.top, 16)
            .padding(.trailing, 20)
            Spacer()
        }
    }

    // ── Header ───────────────────────────────────────────────────

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "bolt.horizontal.circle.fill")
                .font(.system(size: 54, weight: .ultraLight))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.60, green: 0.42, blue: 1.00),
                            Color(red: 1.00, green: 0.65, blue: 0.85)
                        ],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .opacity(heroVisible ? 1 : 0)
                .scaleEffect(heroVisible ? 1 : 0.8)

            Text("Connected to Convex")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            statusPill
        }
    }

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(store.lastError != nil ? Color.orange : (store.isLoading ? Color.yellow : Color.green))
                .frame(width: 8, height: 8)
            Text(statusText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.55))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
    }

    private var statusText: String {
        if let err = store.lastError { return "Error: \(err.prefix(40))" }
        if store.isLoading { return "Subscribing…" }
        return "\(store.items.count) item\(store.items.count == 1 ? "" : "s") · live"
    }

    // ── Content ──────────────────────────────────────────────────

    @ViewBuilder
    private var content: some View {
        if store.items.isEmpty && !store.isLoading {
            VStack(spacing: 8) {
                Spacer()
                Text("No items yet")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.7))
                Text("Add one below — it round-trips through Convex\nand streams back live.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(.horizontal, 28)
        } else {
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(store.items) { item in
                        HStack {
                            Text(item.text)
                                .font(.system(size: 16, design: .rounded))
                                .foregroundStyle(.white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.06))
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // ── Composer ─────────────────────────────────────────────────

    private var composer: some View {
        HStack(spacing: 10) {
            TextField("Add an item…", text: $draft)
                .textFieldStyle(.plain)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
                .submitLabel(.send)
                .onSubmit(send)

            Button(action: send) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(.white))
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(draft.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
        }
    }

    private func send() {
        let text = draft
        draft = ""
        Task { await store.add(text) }
    }

    // ── Background ───────────────────────────────────────────────

    private var background: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(
                colors: [Color(red: 0.28, green: 0.14, blue: 0.72).opacity(0.5), Color.clear],
                center: .init(x: 0.5, y: 0.18), startRadius: 0, endRadius: 360
            )
            .ignoresSafeArea()
        }
    }
}

#Preview {
    DemoFeed(auth: nil)
}
