# OldTube Channel Player（仮名）

任意の YouTube チャンネルの投稿動画を **古い順** に並べ、YouTube 公式の埋め込みプレイヤーで
順番に視聴しやすくする iPhone アプリです。

> YouTube の規約・API ポリシーに配慮した設計です。動画ファイルのダウンロードや独自プレイヤーでの
> 直接再生、広告・再生制限の回避、スクレイピングは一切行いません。動画一覧の取得は
> **YouTube Data API v3**、再生は **YouTube IFrame Player API（WKWebView 経由の公式埋め込み）** を使用します。

---

## 主な機能（MVP）

- チャンネルURL入力（`@handle` / `/channel/UC...` / `/c/name` / `/user/name`）
- チャンネル解決 → アップロード動画一覧の取得（ページネーション対応）
- **publishedAt 昇順（古い順）** での一覧表示、古い順 / 新しい順の切り替え
- サムネイル・タイトル・公開日・視聴済みマーク付きリスト
- 公式 IFrame プレイヤーでの再生、前へ / 次へ / 視聴済み / YouTubeで開く
- お気に入り（最近使った）チャンネルのローカル保存
- 視聴履歴（videoId 単位）のローカル保存
- APIキー未設定・通信エラー時の日本語エラー表示

---

## 必要環境

- macOS + **Xcode 15 以降**（iOS 17.0 以降をターゲット）
- iPhone 実機またはシミュレータ（iOS 17+）
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)（`.xcodeproj` を生成するために使用）
  - 未インストールなら: `brew install xcodegen`
- YouTube Data API v3 の APIキー

> 注: 本リポジトリには `.xcodeproj` を含めず、`project.yml` から XcodeGen で生成する方式です。
> Xcode で「新規 App プロジェクトを作成し、各 Swift ファイルを取り込む」手順でも構いません。

---

## YouTube Data API v3 APIキーの取得

1. [Google Cloud Console](https://console.cloud.google.com/) でプロジェクトを作成
2. 「APIとサービス」→「ライブラリ」で **YouTube Data API v3** を有効化
3. 「認証情報」→「認証情報を作成」→「APIキー」でキーを発行
4. （推奨）APIキーに「iOSアプリ」制限・「YouTube Data API v3」制限をかける

> 無料枠は1日あたり 10,000 quota units です。`search.list`（カスタムURL解決時）は100 units、
> `playlistItems.list` は1ページ1 unit 程度です。大きなチャンネルは消費に注意してください。

---

## Config.plist の作り方

APIキーはコードに直書きしません。`Resources/Config.example.plist` をコピーして
`Resources/Config.plist` を作成し、APIキーを設定します。

```bash
cp Resources/Config.example.plist Resources/Config.plist
```

`Resources/Config.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>YOUTUBE_API_KEY</key>
    <string>（取得した実APIキー）</string>
</dict>
</plist>
```

`Config.plist` は `.gitignore` 済みでコミットされません。
（CI・デバッグ用に、環境変数 `YOUTUBE_API_KEY` でも読み込めます。）

---

## ビルド方法

```bash
# 1) プロジェクトを生成
xcodegen generate

# 2) Xcode で開く
open OldTubeChannelPlayer.xcodeproj

# 3) ターゲット OldTubeChannelPlayer を実機/シミュレータで実行（Cmd+R）
#    テスト実行は Cmd+U
```

コマンドラインからのビルド例:

```bash
xcodebuild -project OldTubeChannelPlayer.xcodeproj \
  -scheme OldTubeChannelPlayer \
  -destination 'platform=iOS Simulator,name=iPhone 15' build

# テスト
xcodebuild -project OldTubeChannelPlayer.xcodeproj \
  -scheme OldTubeChannelPlayer \
  -destination 'platform=iOS Simulator,name=iPhone 15' test
```

---

## GitHub Actions でのビルド確認（CI）

ローカルが Windows などで Xcode を使えない場合でも、**GitHub Actions の macOS ランナー**で
コンパイル確認ができます。ワークフロー: [`.github/workflows/ios-build.yml`](.github/workflows/ios-build.yml)

やっていること:

1. `macos-14` ランナー（Xcode 15.x / iOS 17 SDK）で実行
2. `brew install xcodegen` → `xcodegen generate` で `.xcodeproj` を生成
3. `Resources/Config.example.plist` を `Config.plist` にコピーし、`YOUTUBE_API_KEY` に **CI用ダミー値** を設定
4. **署名なし・シミュレーター向けに Debug ビルド**（`CODE_SIGNING_ALLOWED=NO`、`generic/platform=iOS Simulator`）
5. 続けて **ユニットテスト** を実行（`iPhone 15` シミュレーター）

使い方:

```bash
# このフォルダ(OldTubeChannelPlayer)を GitHub リポジトリのルートとして push する
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/<your-account>/<repo>.git
git push -u origin main
```

- push（または PR）すると自動でビルドが走ります。**Actions タブ**から手動実行（Run workflow）も可能です。
- 結果・ログは GitHub の **Actions** タブで確認できます。失敗時はログにビルドエラーがそのまま出るので、
  内容を共有いただければ修正できます。
- App Store 配布・実機配布・Apple Developer Program の設定は不要です（CIはコンパイル確認のみ）。
- テスト用シミュレーター名（`iPhone 15`）がランナーに無い場合は、ログの「Show available simulators」を見て
  `ios-build.yml` の `TEST_DESTINATION` を調整してください。

> 注: `.xcodeproj` と `Config.plist` は `.gitignore` 済みでコミットされません。CI 側でその都度生成・作成します。
> リポジトリには Swift ソース・`project.yml`・`Config.example.plist` があれば十分です。

---

## ディレクトリ構成

```
OldTubeChannelPlayer/
  App/        OldTubeChannelPlayerApp.swift
  Models/     Channel.swift / VideoItem.swift / WatchHistory.swift
  Services/   ConfigLoader / YouTubeAPIError / ChannelResolver /
              YouTubeAPIClient / WatchHistoryStore / FavoriteChannelStore
  ViewModels/ ChannelInputViewModel / VideoListViewModel / PlayerViewModel
  Views/      ChannelInputView / FavoriteChannelsView / VideoListView /
              PlayerView / YouTubePlayerWebView
  Resources/  Config.example.plist（Config.plist は各自作成）
  Tests/      ChannelResolverTests / VideoSortTests / WatchHistoryStoreTests
  project.yml（XcodeGen 用）
```

技術スタック: Swift / SwiftUI / MVVM / async-await / WKWebView / YouTube Data API v3 / UserDefaults。

---

## 注意事項（YouTube規約への配慮）

- 動画は **必ず公式の IFrame Player（WKWebView 埋め込み）** で再生します。独自プレイヤーや
  ダウンロードは行いません。
- 自動再生は控えめにしています。再生終了時も**自動で次を再生し続けることはせず**、
  「次へ」ボタンなどユーザー操作を挟みます。
- 広告・YouTube UI・再生制限の回避は行いません。
- 動画一覧の取得は Data API v3 のみで、スクレイピングはしません。
- 公開する場合は、最新の [YouTube API サービス利用規約](https://developers.google.com/youtube/terms/api-services-terms-of-service)
  と [ブランドガイドライン](https://developers.google.com/youtube/terms/branding-guidelines) を必ず再確認してください。

---

## 既知の制約

- アップロードプレイリストは新しい順で返るため、**古い順表示には全ページの取得が必要**です。
  動画数の多いチャンネルでは初回読み込みに時間がかかり、quota も消費します（安全のため最大100ページ）。
- カスタムURL（`/c/name` や `/name`）は `search.list`（100 units）で channelId を解決するため、
  ヒット精度は YouTube 検索に依存します。`@handle` / `/channel/UC...` が最も確実です。
- IFrame の `ended` イベントが取得できない場合は、「次へ」ボタンで手動遷移してください。

---

## 今後の改善案

- プレイリスト単位の古い順再生
- 複数チャンネルのお気に入り管理の強化
- 視聴進捗率（途中までの再生位置）の保存
- 動画検索・絞り込み
- iPad 対応
- CloudKit による端末間同期
- App Store 提出前の YouTube API ポリシー再確認
