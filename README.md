# swift-convex-template

Botflow Swift app template with a **Convex** backend. iOS 18, SwiftUI, Swift 6,
XcodeGen — same as the base Swift template, plus a live Convex data layer.

## What's different from the plain Swift template

- **Convex is the backend AND the data layer.** There is **no SwiftData** —
  no `@Model`, no `ModelContainer`. The Convex sync engine is the single source
  of truth and delivers live query results over the network. A local store would
  be a competing source of truth, so we don't have one.
- **`ConvexMobile` SDK** (`get-convex/convex-swift`, pinned at `0.8.1`) is linked
  via XcodeGen. It wraps the Convex Rust client and ships a prebuilt
  `.xcframework`.
- A co-located **`convex/`** TypeScript backend — identical in shape to the web
  template. The same Botflow deploy pipeline pushes it.

## Layout

```
Sources/
  App/MyApp.swift               @main App (no ModelContainer)
  Core/
    ConvexConfig.swift          deployment URL — PLATFORM-MANAGED, do not edit
    ConvexClient+Shared.swift   shared ConvexClient (Convex.shared)
  Models/Item.swift             Decodable/Identifiable struct (mirror schema.ts)
  ViewModels/ItemsStore.swift   @Observable store; subscribe + mutation (≈ useQuery)
  Views/ContentView.swift       live demo: list + add, streamed from Convex
convex/
  schema.ts                     tables (source of truth)
  items.ts                      list query + add mutation
  tsconfig.json
package.json                    declares the convex toolchain version (deploy)
project.yml                     XcodeGen spec (ConvexMobile package + arch fix)
Package.resolved                FROZEN SwiftPM pin — committed on purpose
Makefile                        make generate / build / clean
```

## How the client maps to Convex (the `useQuery` analog)

```swift
// subscribe → live results, rebuilds the UI on every change
Convex.shared.subscribe(to: "items:list", yielding: [Item].self).values
// mutation → write; the subscription pushes the updated list automatically
try await Convex.shared.mutation("items:add", with: ["text": text])
```

Keep `Sources/Models/*.swift` in sync with `convex/schema.ts` **by hand** —
there is no Swift codegen from the Convex schema (unlike the web `_generated` API).

## Build (remote Mac / controller)

```sh
make build        # xcodegen generate → restore frozen resolved → xcodebuild (simulator)
```

### Two things that make the Convex SDK build reliably

1. **arm64-only simulator slice.** `libconvexmobile-rs.xcframework` has no
   `x86_64` simulator slice, so `project.yml` sets
   `EXCLUDED_ARCHS[sdk=iphonesimulator*] = x86_64`. Botflow's controller +
   Simulator are Apple Silicon, so this is correct. Without it the build fails
   with *"missing architecture(s) required by this target (x86_64)"*.
2. **Frozen, no-network resolution.** `Package.resolved` is committed at the repo
   root (the `.xcodeproj` is gitignored/regenerated). `make generate` copies it
   back into the workspace, and `make build` passes
   `-onlyUsePackageVersionsFromResolvedFile -disableAutomaticPackageResolution`
   so the build uses the controller's pre-warmed SwiftPM cache and **never
   fetches over the network** in the hot loop.

To bump the SDK: edit `exactVersion` in `project.yml`, run `make generate` +
`xcodebuild -resolvePackageDependencies` on a networked Mac, copy the new
`Package.resolved` to the repo root, and re-warm the controller cache.

## Auth

The template ships **un-authenticated by default** and turns auth on without a
template swap. When Botflow runs `setupAuth` for the project it configures
`@convex-dev/auth` on the deployment (the same backend the web projects use) and
flips `ConvexConfig.authEnabled` to `true`; the auth scaffolding below then
activates.

Instead of a native sign-in form, the app opens the **Convex Auth password flow
in an in-app browser** (`ASWebAuthenticationSession`) — a page served from this
deployment's own `*.convex.site` origin. That page signs in and redirects back to
`botflowauth://auth-callback#token=…&refresh=…`; the app stores the refresh token
in the Keychain and hands the JWT to `ConvexClientWithAuth`. Because the web page
is the form, the `@convex-dev/auth` backend carries over from the web template
unchanged — no first-party Swift `AuthProvider` (Clerk/Auth0) is required.

- `Sources/Core/BotflowAuthProvider.swift` — the `AuthProvider`: in-app-browser
  sign-in, silent refresh via the `auth:signIn` action, Keychain persistence.
- `Sources/Core/Keychain.swift` — refresh-token storage.
- `Sources/ViewModels/AuthStore.swift` — observable auth state for the UI.
- `Sources/Views/SignInView.swift` — the button that launches sign-in.
- `Sources/Core/ConvexClient+Shared.swift` — selects `ConvexClientWithAuth` when
  `authEnabled`.

OAuth (Google) and magic-link are out of scope for now (the hosted page is built
so the OAuth redirect can be added later).

## Verified

`make build` produces **BUILD SUCCEEDED** for the iOS Simulator (Xcode 16.4,
arm64), including a clean offline-resolution rebuild. See
`future/swift-convex-backend.md` in the Botflow repo for the full plan.
