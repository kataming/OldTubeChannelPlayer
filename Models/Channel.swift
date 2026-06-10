import Foundation

/// YouTube チャンネルを表すモデル。
struct Channel: Identifiable, Codable, Hashable {
    /// channelId（例: UCxxxxxxxxxxxxxxxxxxxxxx）
    let id: String
    let title: String
    let thumbnailURL: URL?
    /// アップロード動画のプレイリストID（contentDetails.relatedPlaylists.uploads）
    var uploadsPlaylistId: String?
}

/// お気に入り保存用のチャンネル。最終オープン日時を持つ。
struct FavoriteChannel: Identifiable, Codable, Hashable {
    let id: String              // channelId
    let title: String
    let thumbnailURL: URL?
    let uploadsPlaylistId: String?
    var lastOpenedAt: Date

    init(channel: Channel, lastOpenedAt: Date = Date()) {
        self.id = channel.id
        self.title = channel.title
        self.thumbnailURL = channel.thumbnailURL
        self.uploadsPlaylistId = channel.uploadsPlaylistId
        self.lastOpenedAt = lastOpenedAt
    }

    /// 一覧画面で使う Channel へ変換する。
    var asChannel: Channel {
        Channel(id: id, title: title, thumbnailURL: thumbnailURL, uploadsPlaylistId: uploadsPlaylistId)
    }
}
