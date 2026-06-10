import Foundation

@MainActor
final class PlayerViewModel: ObservableObject {
    @Published private(set) var currentIndex: Int
    @Published var playerState: YouTubePlayerState = .unstarted
    /// 再生終了後に「次の動画」を提示するか。自動再生はしない。
    @Published var showEndedSuggestion = false

    let videos: [VideoItem]
    private let watchStore: WatchHistoryStore

    init(videos: [VideoItem], startIndex: Int, watchStore: WatchHistoryStore) {
        self.videos = videos
        if videos.isEmpty {
            self.currentIndex = 0
        } else {
            self.currentIndex = max(0, min(startIndex, videos.count - 1))
        }
        self.watchStore = watchStore
    }

    var currentVideo: VideoItem? {
        videos.indices.contains(currentIndex) ? videos[currentIndex] : nil
    }
    var canGoPrevious: Bool { currentIndex > 0 }
    var canGoNext: Bool { currentIndex < videos.count - 1 }
    var nextVideo: VideoItem? { canGoNext ? videos[currentIndex + 1] : nil }

    func goNext() {
        guard canGoNext else { return }
        currentIndex += 1
        showEndedSuggestion = false
    }

    func goPrevious() {
        guard canGoPrevious else { return }
        currentIndex -= 1
        showEndedSuggestion = false
    }

    func markCurrentWatched() {
        guard let video = currentVideo else { return }
        watchStore.markWatched(video.id)
    }

    func isCurrentWatched() -> Bool {
        guard let video = currentVideo else { return false }
        return watchStore.isWatched(video.id)
    }

    /// IFrame Player の状態変化を受け取る。
    func handleState(_ state: YouTubePlayerState) {
        playerState = state
        if state == .ended {
            // 終了したら視聴済みにし、次の動画を「提示」するのみ（自動再生しない）。
            markCurrentWatched()
            showEndedSuggestion = canGoNext
        }
    }
}
