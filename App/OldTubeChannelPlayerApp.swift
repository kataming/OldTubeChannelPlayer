import SwiftUI

@main
struct OldTubeChannelPlayerApp: App {
    // アプリ全体で共有するローカルストア。
    @StateObject private var watchHistoryStore = WatchHistoryStore()
    @StateObject private var favoriteStore = FavoriteChannelStore()

    var body: some Scene {
        WindowGroup {
            ChannelInputView()
                .environmentObject(watchHistoryStore)
                .environmentObject(favoriteStore)
        }
    }
}
