import XCTest
@testable import ChannelTimelineViewer

@MainActor
final class ChannelProgressStoreTests: XCTestCase {

    private func makeDefaults() -> UserDefaults {
        let suite = "test.progress.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suite)!
        d.removePersistentDomain(forName: suite)
        return d
    }

    func testProgressRateCalculation() {
        let store = ChannelProgressStore(defaults: makeDefaults())
        store.updateCounts(channelId: "C1", totalVideoCount: 120, watchedVideoCount: 12)
        let p = store.progress(for: "C1")
        XCTAssertEqual(p?.totalVideoCount, 120)
        XCTAssertEqual(p?.watchedVideoCount, 12)
        XCTAssertEqual(p?.progressRate ?? 0, 0.1, accuracy: 0.0001)
    }

    func testProgressRateZeroWhenNoVideos() {
        let p = ChannelProgress(channelId: "X", totalVideoCount: 0, watchedVideoCount: 0)
        XCTAssertEqual(p.progressRate, 0)
    }

    func testProgressRateCappedAtOne() {
        let p = ChannelProgress(channelId: "X", totalVideoCount: 5, watchedVideoCount: 9)
        XCTAssertEqual(p.progressRate, 1.0, accuracy: 0.0001)
    }

    func testRecordLastOpenedVideoId() {
        let store = ChannelProgressStore(defaults: makeDefaults())
        store.recordOpened(channelId: "C1", videoId: "vid123")
        XCTAssertEqual(store.progress(for: "C1")?.lastOpenedVideoId, "vid123")
        XCTAssertNotNil(store.progress(for: "C1")?.lastOpenedAt)
    }

    func testRecordLastOpenedAtSaved() {
        let store = ChannelProgressStore(defaults: makeDefaults())
        let date = Date(timeIntervalSince1970: 12345)
        store.recordOpened(channelId: "C1", videoId: "v", at: date)
        XCTAssertEqual(store.progress(for: "C1")?.lastOpenedAt, date)
    }

    func testUpdateCountsKeepsLastOpened() {
        let store = ChannelProgressStore(defaults: makeDefaults())
        store.recordOpened(channelId: "C1", videoId: "vidA")
        store.updateCounts(channelId: "C1", totalVideoCount: 10, watchedVideoCount: 3)
        let p = store.progress(for: "C1")
        XCTAssertEqual(p?.lastOpenedVideoId, "vidA")   // 上書きされない
        XCTAssertEqual(p?.totalVideoCount, 10)
    }

    func testPersistenceAcrossInstances() {
        let defaults = makeDefaults()
        let s1 = ChannelProgressStore(defaults: defaults)
        s1.updateCounts(channelId: "C9", totalVideoCount: 50, watchedVideoCount: 25)
        let s2 = ChannelProgressStore(defaults: defaults)
        XCTAssertEqual(s2.progress(for: "C9")?.watchedVideoCount, 25)
    }
}
