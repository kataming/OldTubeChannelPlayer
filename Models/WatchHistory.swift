import Foundation

/// 視聴履歴（videoId 単位）。
struct WatchHistory: Codable, Hashable, Identifiable {
    let videoId: String
    var watchedAt: Date?

    var id: String { videoId }
}
