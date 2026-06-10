import XCTest
@testable import ChannelTimelineViewer

final class VideoSortTests: XCTestCase {

    private func video(_ id: String, epoch: TimeInterval) -> VideoItem {
        VideoItem(id: id,
                  title: id,
                  description: "",
                  publishedAt: Date(timeIntervalSince1970: epoch),
                  thumbnailURL: nil,
                  channelId: "channel")
    }

    func testAscendingIsOldestFirst() {
        let items = [video("c", epoch: 300), video("a", epoch: 100), video("b", epoch: 200)]
        let sorted = items.sortedByPublishedDate(ascending: true)
        XCTAssertEqual(sorted.map(\.id), ["a", "b", "c"])
    }

    func testDescendingIsNewestFirst() {
        let items = [video("c", epoch: 300), video("a", epoch: 100), video("b", epoch: 200)]
        let sorted = items.sortedByPublishedDate(ascending: false)
        XCTAssertEqual(sorted.map(\.id), ["c", "b", "a"])
    }

    func testEmptyStaysEmpty() {
        XCTAssertTrue([VideoItem]().sortedByPublishedDate(ascending: true).isEmpty)
    }
}
