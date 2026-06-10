import Foundation

/// APIキーなどの設定を読み込む。
/// 優先順位: 環境変数 YOUTUBE_API_KEY → バンドル内 Config.plist。
/// キーはコードに直書きしない。
enum ConfigLoader {
    static let apiKeyName = "YOUTUBE_API_KEY"
    private static let placeholder = "YOUR_API_KEY_HERE"

    /// YouTube Data API v3 のAPIキー。未設定なら nil。
    static func youtubeAPIKey() -> String? {
        // 1) 環境変数（CI やデバッグ用。Xcode の Scheme でも設定可能）
        if let env = ProcessInfo.processInfo.environment[apiKeyName],
           isUsable(env) {
            return env.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 2) バンドル内の Config.plist
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let key = dict[apiKeyName] as? String,
              isUsable(key) else {
            return nil
        }
        return key.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static var isConfigured: Bool { youtubeAPIKey() != nil }

    /// プライバシーポリシーURL。未設定（プレースホルダ/空）なら nil。
    static func privacyPolicyURL() -> URL? {
        let name = "PRIVACY_POLICY_URL"
        var raw: String?
        if let env = ProcessInfo.processInfo.environment[name], isUsable(env) {
            raw = env
        } else if let url = Bundle.main.url(forResource: "Config", withExtension: "plist"),
                  let data = try? Data(contentsOf: url),
                  let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
                  let value = dict[name] as? String, isUsable(value),
                  value != "YOUR_PRIVACY_POLICY_URL_HERE" {
            raw = value
        }
        guard let raw = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              let url = URL(string: raw), url.scheme?.hasPrefix("http") == true else {
            return nil
        }
        return url
    }

    private static func isUsable(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != placeholder
    }
}
