import Foundation

/// 動画単位の簡易メモ（シリーズ視聴・学習用）。
struct VideoMemo: Codable, Hashable, Identifiable {
    let videoId: String
    var memo: String
    var updatedAt: Date

    var id: String { videoId }
}
