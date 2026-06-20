// ─────────────────────────────────────────────────────────────────
// SignInView.swift — Sign-in entry point
//
// Deliberately minimal: there is NO native email/password form here. The
// actual form is the Convex Auth web page, opened in an in-app browser by
// `AuthStore.signIn()` (the same flow web Botflow projects use). This screen
// is just the button that launches it — Botflow replaces/restyles it once the
// user describes their real sign-in screen.
// ─────────────────────────────────────────────────────────────────

import SwiftUI

struct SignInView: View {
    @Bindable var auth: AuthStore
    @State private var working = false

    var body: some View {
        ZStack {
            background

            VStack(spacing: 18) {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 56, weight: .ultraLight))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.60, green: 0.42, blue: 1.00),
                                Color(red: 1.00, green: 0.65, blue: 0.85)
                            ],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )

                Text("Sign in")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("Continue to your account.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.45))

                Button(action: signIn) {
                    HStack(spacing: 8) {
                        if working { ProgressView().tint(.black) }
                        Text(working ? "Opening…" : "Continue")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(RoundedRectangle(cornerRadius: 14).fill(.white))
                }
                .disabled(working)
                .padding(.top, 8)
                .padding(.horizontal, 40)

                if let error = auth.lastError {
                    Text(error)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
        }
    }

    private func signIn() {
        working = true
        Task {
            await auth.signIn()
            working = false
        }
    }

    private var background: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            RadialGradient(
                colors: [Color(red: 0.28, green: 0.14, blue: 0.72).opacity(0.5), Color.clear],
                center: .init(x: 0.5, y: 0.22), startRadius: 0, endRadius: 360
            )
            .ignoresSafeArea()
        }
    }
}
