import XCTest
@testable import OldTubeChannelPlayer

@MainActor
final class WatchHistoryStoreTests: XCTestCase {

    private func makeIsolatedDefaults() -> UserDefaults {
        let suite = "test.watchhistory.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    func testMarkAndQuery() {
        let store = WatchHistoryStore(defaults: makeIsolatedDefaults())
        XCTAssertFalse(store.isWatched("v1"))
        store.markWatched("v1")
        XCTAssertTrue(store.isWatched("v1"))
        XCTAssertEqual(store.watchedCount, 1)
    }

    func testUnmark() {
        let store = WatchHistoryStore(defaults: makeIsolatedDefaults())
        store.markWatched("v1")
        store.unmarkWatched("v1")
        XCTAssertFalse(store.isWatched("v1"))
        XCTAssertEqual(store.watchedCount, 0)
    }

    func testToggle() {
        let store = WatchHistoryStore(defaults: makeIsolatedDefaults())
        store.toggleWatched("v3")
        XCTAssertTrue(store.isWatched("v3"))
        store.toggleWatched("v3")
        XCTAssertFalse(store.isWatched("v3"))
    }

    func testPersistenceAcrossInstances() {
        let defaults = makeIsolatedDefaults()
        let store1 = WatchHistoryStore(defaults: defaults)
        store1.markWatched("v2")

        let store2 = WatchHistoryStore(defaults: defaults)
        XCTAssertTrue(store2.isWatched("v2"))
    }
}
