import Foundation
import Security

/// Minimal Keychain wrapper for the Anthropic API key.
/// Never hardcode secrets in source — set via Keychain or env `ANTHROPIC_API_KEY`.
enum PicassoAPIKeyStore {
    private static let service = "com.picartdo.picasso"
    private static let account = "anthropic_api_key"

    /// Resolve key: Keychain → process environment. Debug builds only: release builds
    /// reach Claude through Supabase Edge Functions, so no key ever ships in the app.
    static func resolve() -> String? {
        #if !DEBUG
        return nil
        #endif
        if let key = loadFromKeychain(), !key.isEmpty { return key }

        let env = ProcessInfo.processInfo.environment
        for name in ["ANTHROPIC_API_KEY", "PICARDO_ANTHROPIC_API_KEY"] {
            if let key = env[name], !key.isEmpty { return key }
        }

        return nil
    }

    static func saveToKeychain(_ key: String) -> Bool {
        let data = Data(key.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    static func loadFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func clear() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
