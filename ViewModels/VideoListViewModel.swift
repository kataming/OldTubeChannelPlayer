import Foundation

@MainActor
final class VideoListViewModel: ObservableObject {
    @Published private(set) var videos: [VideoItem] = []
    /// true = 古い順（publishedAt 昇順）。デフォルトは古い順。
    @Published var sortAscending = true
    @Published var isLoading = false
    @Published var errorMessage: String?

    let channel: Channel
    private let api: YouTubeAPIClient

    init(channel: Channel, api: YouTubeAPIClient = YouTubeAPIClient()) {
        self.channel = channel
        self.api = api
    }

    /// 並び替えを反映した表示用リスト。
    var displayedVideos: [VideoItem] {
        videos.sortedByPublishedDate(ascending: sortAscending)
    }
    var count: Int { videos.count }

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
