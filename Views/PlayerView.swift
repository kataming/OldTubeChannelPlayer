import SwiftUI

struct PlayerView: View {
    // 視聴済み状態の変化で再描画するため EnvironmentObject でも観測する。
    @EnvironmentObject private var watchStore: WatchHistoryStore
    @EnvironmentObject private var progressStore: ChannelProgressStore
    @StateObject private var viewModel: PlayerViewModel
    @Environment(\.openURL) private var openURL
    private let channelId: String

    init(videos: [VideoItem], startIndex: Int, watchStore: WatchHistoryStore, channelId: String) {
        self.channelId = channelId
        _viewModel = StateObject(
            wrappedValue: PlayerViewModel(videos: videos, startIndex: startIndex, watchStore: watchStore)
        )
    }

    var body: some View {
        Group {
            if let video = viewModel.currentVideo {
                VStack(spacing: 0) {
                    YouTubePlayerWebView(
                        videoId: video.id,
                        autoplayOnLoad: true,
                        onStateChange: { state in viewModel.handleState(state) }
                    )
                    .aspectRatio(16.0 / 9.0, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)

                    ScrollView {
                        details(for: video)
                    }
                }
            } else {
                ContentUnavailableView("動画がありません", systemImage: "film")
            }
        }
        .navigationTitle("再生")
        .navigationBarTitleDisplayMode(.inline)
        // 「最後に開いた動画」を記録（続きから見る用）。
        .task { recordOpened() }
        .onChange(of: viewModel.currentIndex) { _, _ in recordOpened() }
    }

    private func recordOpened() {
        guard let video = viewModel.currentVideo else { return }
        progressStore.recordOpened(channelId: channelId, videoId: video.id)
    }

    @ViewBuilder
    private func details(for video: VideoItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(video.title).font(.headline)
            Text(video.publishedAt.formatted(date: .long, time: .omitted))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if viewModel.showEndedSuggestion, let next = viewModel.nextVideo {
                endedSuggestion(next)
            }

            controls(for: video)

            if !video.description.isEmpty {
                Divider()
                Text(video.description)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private func endedSuggestion(_ next: VideoItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("再生が終了しました。次の動画:")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                RemoteThumbnail(url: next.thumbnailURL, width: 88, height: 50)
                Text(next.title).font(.subheadline).lineLimit(2)
            }
            Button {
                viewModel.goNext()
            } label: {
                Label("次の動画を再生", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func controls(for video: VideoItem) -> some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    viewModel.goPrevious()
                } label: {
                    Label("前へ", systemImage: "backward.fill")
                }
                .disabled(!viewModel.canGoPrevious)

                Spacer()

                Button {
                    viewModel.goNext()
                } label: {
                    Label("次へ", systemImage: "forward.fill")
                }
                .disabled(!viewModel.canGoNext)
            }
            .buttonStyle(.bordered)

            let watched = watchStore.isWatched(video.id)
            Button {
                watchStore.toggleWatched(video.id)
            } label: {
                Label(watched ? "視聴済みを解除" : "視聴済みにする",
                      systemImage: watched ? "checkmark.circle.fill" : "checkmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(watched ? .green : .accentColor)

            Button {
                if let url = video.watchURL { openURL(url) }
            } label: {
                Label("YouTubeで開く", systemImage: "play.rectangle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}
