import Foundation

/// チャンネルごとの進捗（総数・視聴済み数・最後に開いた動画）をローカル保存するストア。
/// 将来 SwiftData へ移行しやすいよう、永続化はこのクラスに閉じている。
@MainActor
final class ChannelProgressStore: ObservableObject {
    private let defaults: UserDefaults
    private let storageKey = "channel_progress_v1"

    @Published private(set) var progressByChannel: [String: ChannelProgress] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func progress(for channelId: String) -> ChannelProgress? {
        progressByChannel[channelId]
    }

    /// 動画一覧の読み込み時に総数・視聴済み数を更新する。
    func updateCounts(channelId: String, totalVideoCount: Int, watchedVideoCount: Int) {
        var p = progressByChannel[channelId] ?? ChannelProgress(channelId: channelId)
        p.totalVideoCount = totalVideoCount
        p.watchedVideoCount = watchedVideoCount
        progressByChannel[channelId] = p
        save()
    }

    /// 動画を開いたときに「最後に開いた動画」と日時を記録する（続きから見る用）。
    func recordOpened(channelId: String, videoId: String, at date: Date = Date()) {
        var p = progressByChannel[channelId] ?? ChannelProgress(channelId: channelId)
        p.lastOpenedVideoId = videoId
        p.lastOpenedAt = date
        progressByChannel[channelId] = p
        save()
    }

    func remove(_ channelId: String) {
        progressByChannel.removeValue(forKey: channelId)
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: ChannelProgress].self, from: data) else {
            progressByChannel = [:]
            return
        }
        progressByChannel = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(progressByChannel) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
