import XCTest
@testable import ChannelTimelineViewer

final class ChannelResolverTests: XCTestCase {

    func testChannelIdURL() throws {
        let id = "UC1234567890123456789012" // UC + 22文字 = 24
        XCTAssertEqual(try ChannelResolver.parse("https://www.youtube.com/channel/\(id)"),
                       .channelId(id))
    }

    func testBareChannelId() throws {
        let id = "UCabcdefghijklmnopqrstuv"
        XCTAssertEqual(try ChannelResolver.parse(id), .channelId(id))
    }

    func testHandleURL() throws {
        XCTAssertEqual(try ChannelResolver.parse("https://www.youtube.com/@SomeHandle"),
                       .handle("SomeHandle"))
    }

    func testBareHandle() throws {
        XCTAssertEqual(try ChannelResolver.parse("@SomeHandle"), .handle("SomeHandle"))
    }

    func testUserURL() throws {
        XCTAssertEqual(try ChannelResolver.parse("https://www.youtube.com/user/LegacyName"),
                       .username("LegacyName"))
    }

    func testCustomCURL() throws {
        XCTAssertEqual(try ChannelResolver.parse("https://www.youtube.com/c/CustomName"),
                       .customName("CustomName"))
    }

    func testCustomBareNameURL() throws {
        XCTAssertEqual(try ChannelResolver.parse("https://www.youtube.com/SomeName"),
                       .customName("SomeName"))
    }

    func testWithoutScheme() throws {
        XCTAssertEqual(try ChannelResolver.parse("youtube.com/@handle"), .handle("handle"))
    }

    func testInvalidEmpty() {
        XCTAssertThrowsError(try ChannelResolver.parse("   "))
    }

    func testInvalidNonYouTubeHost() {
        XCTAssertThrowsError(try ChannelResolver.parse("https://example.com/@handle"))
    }

    func testInvalidChannelIdInPath() {
        XCTAssertThrowsError(try ChannelResolver.parse("https://www.youtube.com/channel/NOT_AN_ID"))
    }
}
