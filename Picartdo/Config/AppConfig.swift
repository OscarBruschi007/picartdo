import Foundation

enum AppConfig: Sendable {
    nonisolated static var supabaseURL: URL? {
        url(for: "SUPABASE_URL")
    }

    nonisolated static var supabaseAnonKey: String? {
        string(for: "SUPABASE_ANON_KEY")
    }

    nonisolated static var stripePublishableKey: String? {
        string(for: "STRIPE_PUBLISHABLE_KEY")
    }

    nonisolated static var isBackendConfigured: Bool {
        supabaseURL != nil && supabaseAnonKey != nil
    }

    nonisolated static var functionsURL: URL? {
        guard let base = supabaseURL else { return nil }
        return base.appendingPathComponent("functions/v1")
    }

    nonisolated static var restURL: URL? {
        guard let base = supabaseURL else { return nil }
        return base.appendingPathComponent("rest/v1")
    }

    nonisolated static var authURL: URL? {
        guard let base = supabaseURL else { return nil }
        return base.appendingPathComponent("auth/v1")
    }

    nonisolated static var storageURL: URL? {
        guard let base = supabaseURL else { return nil }
        return base.appendingPathComponent("storage/v1")
    }

    nonisolated private static func string(for key: String) -> String? {
        if let env = ProcessInfo.processInfo.environment[key], !env.isEmpty {
            return env
        }
        if let plist = Bundle.main.object(forInfoDictionaryKey: key) as? String, !plist.isEmpty {
            return plist
        }
        return nil
    }

    nonisolated private static func url(for key: String) -> URL? {
        guard let raw = string(for: key) else { return nil }
        return URL(string: raw)
    }
}
