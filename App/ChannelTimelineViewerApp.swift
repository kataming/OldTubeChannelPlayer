import SwiftUI

@main
struct ChannelTimelineViewerApp: App {
    // アプリ全体で共有するローカルストア。
    @StateObject private var watchHistoryStore = WatchHistoryStore()
    @StateObject private var favoriteStore = FavoriteChannelStore()
    @StateObject private var progressStore = ChannelProgressStore()
    @StateObject private var memoStore = VideoMemoStore()

    var body: some Scene {
        WindowGroup {
            ChannelInputView()
                .environmentObject(watchHistoryStore)
                .environmentObject(favoriteStore)
                .environmentObject(progressStore)
                .environmentObject(memoStore)
        }
    }
}
