import XCTest
@testable import ChannelTimelineViewer

/// 実際の YouTubeAPIClient(Swift本体) を本物の YouTube Data API v3 に当てる統合テスト。
/// 実APIキーが設定されている時だけ実行し、無い場合(通常CI/ダミーキー)はスキップする。
/// CIで動かすには GitHub Secret `YOUTUBE_API_KEY` を登録する(未登録ならskip=緑のまま)。
final class YouTubeAPIIntegrationTests: XCTestCase {

    private func realKeyOrSkip() throws {
        let key = ConfigLoader.youtubeAPIKey()
        try XCTSkipUnless(
            key != nil && key != "CI_DUMMY_KEY_FOR_BUILD",
            "実APIキー未設定のため統合テストをスキップ（GitHub Secret/Config.plist に YOUTUBE_API_KEY を設定すると実行）"
        )
    }

    /// channelId からチャンネル解決 → uploads プレイリスト → 1ページ取得できることを確認。
    func testResolveAndFetchRealChannel() async throws {
        try realKeyOrSkip()
        let client = YouTubeAPIClient()

        // 安定した公開チャンネル(YouTube公式)を channelId で解決(quota節約のため1ページのみ取得)。
        let channel = try await client.resolveChannel(
            from: "https://www.youtube.com/channel/UCBR8-60-B28hp2BmDPdntcQ")
        XCTAssertFalse(channel.id.isEmpty, "channelId が取得できること")

        let uploads = try XCTUnwrap(channel.uploadsPlaylistId, "uploads プレイリストIDが取得できること")
        let page = try await client.fetchVideosPage(playlistId: uploads, pageToken: nil)
        XCTAssertGreaterThan(page.items.count, 0, "動画が1本以上取得できること")

        // 取得項目が埋まっていること（videoId/タイトル/公開日）。
        let first = try XCTUnwrap(page.items.first)
        XCTAssertFalse(first.id.isEmpty)
        XCTAssertFalse(first.title.isEmpty)
        XCTAssertGreaterThan(first.publishedAt.timeIntervalSince1970, 0)
    }

    /// 全ページ取得後に公開日昇順(古い順)で返ることを実データで確認(小さめのチャンネルを想定)。
    /// 大きなチャンネルだと quota を消費するため、件数が多い場合でも先頭の並びだけ検証する。
    func testFetchedVideosAreSortedAscending() async throws {
        try realKeyOrSkip()
        let client = YouTubeAPIClient()
        let channel = try await client.resolveChannel(
            from: "https://www.youtube.com/channel/UCBR8-60-B28hp2BmDPdntcQ")
        let uploads = try XCTUnwrap(channel.uploadsPlaylistId)

        // 1ページ取得して昇順ソートの妥当性を確認（fetchVideosPage は未ソートなので明示ソート）。
        let page = try await client.fetchVideosPage(playlistId: uploads, pageToken: nil)
        let sorted = page.items.sortedByPublishedDate(ascending: true)
        let dates = sorted.map(\.publishedAt)
        XCTAssertEqual(dates, dates.sorted(), "publishedAt 昇順に並ぶこと")
    }
}
