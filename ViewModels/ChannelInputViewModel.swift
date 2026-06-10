import Foundation

@MainActor
final class ChannelInputViewModel: ObservableObject {
    @Published var urlText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    /// 解決できたチャンネル。View はこれを監視して一覧画面へ遷移する。
    @Published var resolvedChannel: Channel?

    private let api: YouTubeAPIClient

    init(api: YouTubeAPIClient = YouTubeAPIClient()) {
        self.api = api
    }

    var isAPIConfigured: Bool { ConfigLoader.isConfigured }

    /// 入力URLからチャンネルを解決し、お気に入りに保存して遷移先を設定する。
    func fetch(favoriteStore: FavoriteChannelStore) async {
        errorMessage = nil

        guard isAPIConfigured else {
            errorMessage = YouTubeAPIError.apiKeyMissing.errorDescription
            return
        }
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = YouTubeAPIError.invalidChannelURL.errorDescription
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            var channel = try await api.resolveChannel(from: trimmed)
            if channel.uploadsPlaylistId == nil {
                channel.uploadsPlaylistId = try await api.fetchUploadsPlaylistId(channelId: channel.id)
            }
            favoriteStore.upsert(channel)
            resolvedChannel = channel
        } catch let error as YouTubeAPIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = YouTubeAPIError.unknown.errorDescription
        }
    }

    /// お気に入りから直接開く。
    func open(_ favorite: FavoriteChannel, favoriteStore: FavoriteChannelStore) {
        favoriteStore.upsert(favorite.asChannel)
        resolvedChannel = favorite.asChannel
    }
}
