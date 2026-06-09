// ─────────────────────────────────────────────────────────────────
// Keychain.swift — minimal Keychain storage for the auth refresh token
//
// The Convex Auth refresh token is the long-lived credential that lets the
// app silently re-authenticate (mint fresh JWTs) without reopening the
// sign-in browser. It belongs in the Keychain, not UserDefaults: it survives
// reinstalls-from-backup appropriately and is protected after first unlock.
//
// Only the refresh token is persisted. The short-lived JWT lives in memory —
// it is always re-derived from the refresh token on launch.
// ─────────────────────────────────────────────────────────────────

import Foundation
import Security

enum Keychain {
    /// Keychain account key for this app's Convex Auth refresh token.
    private static let account = "io.botflow.convexauth.refreshToken"

    static func save(refreshToken: String) {
        let data = Data(refreshToken.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
        ]
        // Replace any existing value (SecItemUpdate can't add, so delete+add).
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func loadRefreshToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8)
        else { return nil }
        return token
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
