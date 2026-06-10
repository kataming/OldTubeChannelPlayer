import XCTest
@testable import ChannelTimelineViewer

@MainActor
final class VideoMemoStoreTests: XCTestCase {

    private func makeDefaults() -> UserDefaults {
        let suite = "test.memo.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suite)!
        d.removePersistentDomain(forName: suite)
        return d
    }

    func testSaveAndReadMemo() {
        let store = VideoMemoStore(defaults: makeDefaults())
        XCTAssertEqual(store.memo(for: "v1"), "")
        store.setMemo("ここから学習再開。要点メモ。", for: "v1")
        XCTAssertEqual(store.memo(for: "v1"), "ここから学習再開。要点メモ。")
        XCTAssertTrue(store.hasMemo(for: "v1"))
    }

    func testEmptyMemoRemoves() {
        let store = VideoMemoStore(defaults: makeDefaults())
        store.setMemo("一時メモ", for: "v2")
        store.setMemo("   ", for: "v2")   // 空白のみ → 削除
        XCTAssertEqual(store.memo(for: "v2"), "")
        XCTAssertFalse(store.hasMemo(for: "v2"))
    }

    func testJapaneseInputPreserved() {
        let store = VideoMemoStore(defaults: makeDefaults())
        let text = "第3回までに復習。アファメーション→行動エネルギー。"
        store.setMemo(text, for: "v3")
        XCTAssertEqual(store.memo(for: "v3"), text)
    }

    func testPersistenceAcrossInstances() {
        let defaults = makeDefaults()
        let s1 = VideoMemoStore(defaults: defaults)
        s1.setMemo("保存テスト", for: "v9")
        let s2 = VideoMemoStore(defaults: defaults)
        XCTAssertEqual(s2.memo(for: "v9"), "保存テスト")
    }
}
