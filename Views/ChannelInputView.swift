import SwiftUI

struct ChannelInputView: View {
    @EnvironmentObject private var favoriteStore: FavoriteChannelStore
    @StateObject private var viewModel = ChannelInputViewModel()
    @State private var showAbout = false

    var body: some View {
        NavigationStack {
            Form {
                if !viewModel.isAPIConfigured {
                    Section {
                        Label("APIキーが設定されていません", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text("Config.plist に YOUTUBE_API_KEY を設定してください。設定方法は README を参照してください。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    TextField("https://www.youtube.com/@handle", text: $viewModel.urlText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .submitLabel(.go)
                        .onSubmit { startFetch() }

                    Button(action: startFetch) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView().padding(.trailing, 4)
                            }
                            Text(viewModel.isLoading ? "取得中..." : "動画を取得")
                        }
                    }
                    .disabled(viewModel.isLoading ||
                              viewModel.urlText.trimmingCharacters(in: .whitespaces).isEmpty)
                } header: {
                    Text("チャンネルURL")
                } footer: {
                    Text("例: https://www.youtube.com/@handle, /channel/UC..., /c/name, /user/name")
                }

                if let error = viewModel.errorMessage {
                    Section {
                        Label(error, systemImage: "xmark.octagon.fill")
                            .foregroundStyle(.red)
                    }
                }

                if !favoriteStore.favorites.isEmpty {
                    Section("最近使ったチャンネル") {
                        FavoriteChannelsView { favorite in
                            viewModel.open(favorite, favoriteStore: favoriteStore)
                        }
                    }
                }

                Section {
                    Text("このアプリは YouTube 公式アプリではありません。再生は YouTube 公式の埋め込みプレイヤーを使用し、ダウンロード・広告回避・バックグラウンド再生は行いません。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Channel Timeline")
            .navigationDestination(item: $viewModel.resolvedChannel) { channel in
                VideoListView(channel: channel)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAbout = true
                    } label: {
                        Image(systemName: "info.circle")
                    }
                    .accessibilityLabel("このアプリについて")
                }
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
        }
    }

    private func startFetch() {
        Task { await viewModel.fetch(favoriteStore: favoriteStore) }
    }
}
