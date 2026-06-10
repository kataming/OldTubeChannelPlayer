import Foundation

/// お気に入りチャンネルをローカル（UserDefaults）に保存するストア。
@MainActor
final class FavoriteChannelStore: ObservableObject {
    private let defaults: UserDefaults
    private let storageKey = "favorite_channels_v1"

    /// lastOpenedAt の新しい順で公開する。
    @Published private(set) var favorites: [FavoriteChannel] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    /// チャンネルを保存（既存なら lastOpenedAt を更新）する。
    func upsert(_ channel: Channel, openedAt: Date = Date()) {
        var list = favorites
        let updated = FavoriteChannel(channel: channel, lastOpenedAt: openedAt)
        if let index = list.firstIndex(where: { $0.id == channel.id }) {
            list[index] = updated
        } else {
            list.append(updated)
        }
        favorites = sortedByRecent(list)
        save()
    }

    func remove(_ id: String) {
        favorites.removeAll { $0.id == id }
        save()
    }

    func removeAtOffsets(_ offsets: IndexSet) {
        favorites.remove(atOffsets: offsets)
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([FavoriteChannel].self, from: data) else {
            favorites = []
            return
        }
        favorites = sortedByRecent(decoded)
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(favorites) else { return }
        defaults.set(data, forKey: storageKey)
    }

    private func sortedByRecent(_ list: [FavoriteChannel]) -> [FavoriteChannel] {
        list.sorted { $0.lastOpenedAt > $1.lastOpenedAt }
    }
}
