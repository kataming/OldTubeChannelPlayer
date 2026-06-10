import XCTest
@testable import ChannelTimelineViewer

@MainActor
final class FavoriteChannelStoreTests: XCTestCase {

    private func makeDefaults() -> UserDefaults {
        let suite = "test.favorite.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suite)!
        d.removePersistentDomain(forName: suite)
        return d
    }

    private func channel(_ id: String, _ title: String) -> Channel {
        Channel(id: id, title: title, thumbnailURL: nil, uploadsPlaylistId: "UU\(id)")
    }

    func testSaveAndList() {
        let store = FavoriteChannelStore(defaults: makeDefaults())
        XCTAssertTrue(store.favorites.isEmpty)
        store.upsert(channel("c1", "Ch1"))
        store.upsert(channel("c2", "Ch2"))
        XCTAssertEqual(store.favorites.count, 2)
        XCTAssertTrue(store.favorites.contains { $0.id == "c1" })
    }

    func testUpsertUpdatesWithoutDuplicate() {
        let store = FavoriteChannelStore(defaults: makeDefaults())
        store.upsert(channel("c1", "Ch1"), openedAt: Date(timeIntervalSince1970: 100))
        store.upsert(channel("c1", "Ch1 updated"), openedAt: Date(timeIntervalSince1970: 200))
        XCTAssertEqual(store.favorites.count, 1, "同じチャンネルは重複保存しない")
        XCTAssertEqual(store.favorites.first?.title, "Ch1 updated")
        XCTAssertEqual(store.favorites.first?.lastOpenedAt, Date(timeIntervalSince1970: 200))
    }

    func testSortedByMostRecent() {
        let store = FavoriteChannelStore(defaults: makeDefaults())
        store.upsert(channel("old", "Old"), openedAt: Date(timeIntervalSince1970: 100))
        store.upsert(channel("new", "New"), openedAt: Date(timeIntervalSince1970: 999))
        XCTAssertEqual(store.favorites.first?.id, "new", "最終オープンが新しい順")
    }

    func testRemoveById() {
        let store = FavoriteChannelStore(defaults: makeDefaults())
        store.upsert(channel("c1", "Ch1"))
        store.upsert(channel("c2", "Ch2"))
        store.remove("c1")
        XCTAssertEqual(store.favorites.map(\.id), ["c2"])
    }

    func testRemoveAtOffsets() {
        let store = FavoriteChannelStore(defaults: makeDefaults())
        store.upsert(channel("a", "A"), openedAt: Date(timeIntervalSince1970: 300))
        store.upsert(channel("b", "B"), openedAt: Date(timeIntervalSince1970: 200))
        store.upsert(channel("c", "C"), openedAt: Date(timeIntervalSince1970: 100))
        // 新しい順: a(300), b(200), c(100) → 先頭(a)を削除
        store.removeAtOffsets(IndexSet(integer: 0))
        XCTAssertEqual(store.favorites.map(\.id), ["b", "c"])
    }

    func testPersistenceAcrossInstances() {
        let defaults = makeDefaults()
        let s1 = FavoriteChannelStore(defaults: defaults)
        s1.upsert(channel("c9", "Ch9"))
        let s2 = FavoriteChannelStore(defaults: defaults)
        XCTAssertEqual(s2.favorites.map(\.id), ["c9"])
    }
}
