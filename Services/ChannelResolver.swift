import Foundation

/// 入力URLから解決したチャンネル識別子。
enum ChannelIdentifier: Equatable {
    case channelId(String)   // UCxxxx
    case handle(String)      // @ を除いたハンドル
    case username(String)    // 旧 /user/ 形式
    case customName(String)  // /c/name または /name のカスタムURL
}

/// YouTube チャンネルURL（または handle / channelId）を解析する。
/// ネットワークアクセスを行わない純粋関数なのでテストしやすい。
enum ChannelResolver {

    static func parse(_ rawInput: String) throws -> ChannelIdentifier {
        let input = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { throw YouTubeAPIError.invalidChannelURL }

        // 1) 先頭が @ のハンドル単体
        if input.hasPrefix("@") {
            return try makeHandle(String(input.dropFirst()))
        }

        // 2) channelId 単体（UC + 22文字）
        if isChannelId(input) {
            return .channelId(input)
        }

        // 3) URLとして解析（スキーム省略も許容）
        let normalized = input.contains("://") ? input : "https://\(input)"
        guard let comps = URLComponents(string: normalized),
              let host = comps.host?.lowercased(),
              host.contains("youtube.com") || host.contains("youtu.be") else {
            throw YouTubeAPIError.invalidChannelURL
        }

        let segments = comps.path.split(separator: "/").map(String.init)
        guard let first = segments.first else {
            throw YouTubeAPIError.invalidChannelURL
        }

        switch first.lowercased() {
        case "channel":
            guard segments.count >= 2, isChannelId(segments[1]) else {
                throw YouTubeAPIError.invalidChannelURL
            }
            return .channelId(segments[1])
        case "user":
            guard segments.count >= 2 else { throw YouTubeAPIError.invalidChannelURL }
            return .username(segments[1])
        case "c":
            guard segments.count >= 2 else { throw YouTubeAPIError.invalidChannelURL }
            return .customName(segments[1])
        default:
            if first.hasPrefix("@") {
                return try makeHandle(String(first.dropFirst()))
            }
            // youtube.com/SomeName のような旧カスタムURL
            return .customName(first)
        }
    }

    /// UC で始まる24文字の channelId かどうか。
    static func isChannelId(_ s: String) -> Bool {
        guard s.hasPrefix("UC"), s.count == 24 else { return false }
        return s.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
    }

    private static func makeHandle(_ h: String) throws -> ChannelIdentifier {
        let clean = h.trimmingCharacters(in: .whitespaces)
        guard !clean.isEmpty else { throw YouTubeAPIError.invalidChannelURL }
        return .handle(clean)
    }
}
