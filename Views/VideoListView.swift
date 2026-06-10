import SwiftUI

struct VideoListView: View {
    @EnvironmentObject private var watchStore: WatchHistoryStore
    @StateObject private var viewModel: VideoListViewModel

    init(channel: Channel) {
        _viewModel = StateObject(wrappedValue: VideoListViewModel(channel: channel))
    }

    var body: some View {
        content
            .navigationTitle(viewModel.channel.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Picker("並び替え", selection: $viewModel.sortAscending) {
                        Text("古い順").tag(true)
                        Text("新しい順").tag(false)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .task { await viewModel.loadIfNeeded() }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading && viewModel.videos.isEmpty {
            ProgressView("動画を取得中...")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.errorMessage, viewModel.videos.isEmpty {
            ContentUnavailableView {
                Label("取得できませんでした", systemImage: "exclamationmark.triangle")
            } description: {
                Text(error)
            } actions: {
                Button("再試行") { Task { await viewModel.load() } }
            }
        } else {
            list
        }
    }

    private var list: some View {
        List {
            Section {
                let videos = viewModel.displayedVideos
                ForEach(Array(videos.enumerated()), id: \.element.id) { index, video in
                    NavigationLink {
                        PlayerView(videos: videos, startIndex: index, watchStore: watchStore)
                    } label: {
                        VideoRow(video: video, watched: watchStore.isWatched(video.id))
                    }
                }
            } header: {
                Text("\(viewModel.count)本")
            }
        }
        .listStyle(.plain)
    }
}

private struct VideoRow: View {
    let video: VideoItem
    let watched: Bool

    var body: some View {
        HStack(spacing: 12) {
            RemoteThumbnail(url: video.thumbnailURL)
            VStack(alignment: .leading, spacing: 4) {
                Text(video.title)
                    .font(.subheadline)
                    .lineLimit(2)
                Text(video.publishedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            if watched {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 4)
    }
}
