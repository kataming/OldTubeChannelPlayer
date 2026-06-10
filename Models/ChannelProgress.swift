import Foundation

/// チャンネル単位の視聴進捗。学習教材のような進捗表示に使う。
struct ChannelProgress: Codable, Hashable {
    let channelId: String
    var totalVideoCount: Int
    var watchedVideoCount: Int
    var lastOpenedVideoId: String?
    var lastOpenedAt: Date?

    /// 進捗率（0.0〜1.0）。総数0なら0。
    var progressRate: Double {
        guard totalVideoCount > 0 else { return 0 }
        return min(1.0, Double(watchedVideoCount) / Double(totalVideoCount))
    }

    init(channelId: String,
         totalVideoCount: Int = 0,
         watchedVideoCount: Int = 0,
         lastOpenedVideoId: String? = nil,
         lastOpenedAt: Date? = nil) {
        self.channelId = channelId
        self.totalVideoCount = totalVideoCount
        self.watchedVideoCount = watchedVideoCount
        self.lastOpenedVideoId = lastOpenedVideoId
        self.lastOpenedAt = lastOpenedAt
    }
}
