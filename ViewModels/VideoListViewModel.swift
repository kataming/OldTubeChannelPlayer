import Foundation

/// 視聴状態によるフィルター。
enum WatchFilter: String, CaseIterable, Identifiable {
    case all = "すべて"
    case unwatched = "未視聴のみ"
    case watched = "視聴済みのみ"
    var id: String { rawValue }
}

@MainActor
final class VideoListViewModel: ObservableObject {
    @Published private(set) var videos: [VideoItem] = []
    /// true = 古い順（publishedAt 昇順）。デフォルトは古い順。
    @Published var sortAscending = true
    @Published var watchFilter: WatchFilter = .all
    @Published var isLoading = false
    @Published var errorMessage: String?

    let channel: Channel
    private let api: YouTubeAPIClient

    init(channel: Channel,
         api: YouTubeAPIClient = YouTubeAPIClient(),
         preloadedVideos: [VideoItem] = []) {
        self.channel = channel
        self.api = api
        self.videos = preloadedVideos
    }

    /// 並び替えのみ反映した表示用リスト。
    var displayedVideos: [VideoItem] {
        videos.sortedByPublishedDate(ascending: sortAscending)
    }
    var count: Int { videos.count }

    /// 並び替え＋視聴フィルターを適用した最終リスト。
    /// isWatched で視聴判定を注入するためテストしやすい（View からは watchStore.isWatched を渡す）。
    func visibleVideos(isWatched: (String) -> Bool) -> [VideoItem] {
        let sorted = videos.sortedByPublishedDate(ascending: sortAscending)
        switch watchFilter {
        case .all:
            return sorted
        case .unwatched:
            return sorted.filter { !isWatched($0.id) }
        case .watched:
            return sorted.filter { isWatched($0.id) }
        }
    }

    /// 「次に見る」動画：公開日が最も古い未視聴動画。
    func nextUnwatched(isWatched: (String) -> Bool) -> VideoItem? {
        videos.sortedByPublishedDate(ascending: true).first { !isWatched($0.id) }
    }

    /// 「次に見る」動画が、古い順全体で何本目か（1始まり）。表示用。
    func nextUnwatchedPosition(isWatched: (String) -> Bool) -> Int? {
        let ascending = videos.sortedByPublishedDate(ascending: true)
        guard let idx = ascending.firstIndex(where: { !isWatched($0.id) }) else { return nil }
        return idx + 1
    }

    /// 古い順全体での動画リスト（再生画面に渡す基準リスト）と、その中での index。
    func oldestFirst() -> [VideoItem] {
        videos.sortedByPublishedDate(ascending: true)
    }

    func loadIfNeeded() async {
        guard videos.isEmpty, !isLoading else { return }
        await load()
    }

    func load() async {
        guard let playlistId = channel.uploadsPlaylistId else {
            errorMessage = YouTubeAPIError.uploadsPlaylistNotFound.errorDescription
            return
        }
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }

        do {
            videos = try await api.fetchVideos(playlistId: playlistId)
            if videos.isEmpty {
                errorMessage = "このチャンネルには表示できる動画がありませんでした"
            }
        } catch let error as YouTubeAPIError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = YouTubeAPIError.unknown.errorDescription
        }
    }

    func toggleSort() { sortAscending.toggle() }

    /// 指定動画の表示リスト上のインデックス（再生画面の開始位置に使う）。
    func displayIndex(of video: VideoItem) -> Int {
        displayedVideos.firstIndex(of: video) ?? 0
    }
}
