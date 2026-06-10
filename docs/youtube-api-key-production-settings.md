# YouTube API キー 本番制限設定

> 本アプリは YouTube Data API v3 のキーを iOS アプリのバンドルに含めて使う。
> 漏洩・不正利用に備え、Google Cloud Console で **2つの制限**をかける。
> **このファイルに実際のキーは書かない**こと（キーは `Resources/Config.plist`＝Git管理外、または CI の GitHub Secrets に置く）。

## 前提
- Google Cloud Console: https://console.cloud.google.com/
- 対象プロジェクトで **YouTube Data API v3** を有効化済み
- 認証情報（APIキー）を発行済み

## 1. アプリケーションの制限：iOS Bundle ID 制限
キーを**自分の iOS アプリからのリクエストだけ**に限定する。

1. Google Cloud Console →「APIとサービス」→「**認証情報**」→ 対象の API キーを開く
2. 「アプリケーションの制限」で **「iOS アプリ」** を選択
3. 「iOS バンドル ID」に本アプリの Bundle ID を追加
   - 例：`com.<自分のドメイン>.channeltimelineviewer`（= `project.yml` の `PRODUCT_BUNDLE_IDENTIFIER` と一致させる）
4. 保存

> 注意：
> - Bundle ID を本番値に変えたら、この制限の Bundle ID も必ず一致させる（不一致だと 403 で取得失敗）。
> - シミュレーター/CI（ダミーキー）では実 API を叩かないため影響なし。実機 TestFlight では本番キー＋一致した Bundle ID が必要。

## 2. API の制限：YouTube Data API v3 のみ許可
キーで**呼べる API を YouTube Data API v3 だけ**に限定する（他 Google API への悪用を防ぐ）。

1. 同じ API キーの編集画面で「**API の制限**」→「**キーを制限**」を選択
2. リストから **「YouTube Data API v3」** だけにチェック
3. 保存

## 3. 運用上の注意
- キーは `Resources/Config.plist`（**`.gitignore` 済み**）に置く。リポジトリ・チャット・スクショに貼らない。
- CI では GitHub の **Secrets**（`YOUTUBE_API_KEY`）に置く。`ios-build.yml` は Secret が無ければダミーキーを使う。
- 使用量は Console の「**割り当て**（Quotas）」で監視（無料枠は1日 10,000 units 目安）。不審な増加があればキーを再生成。
- **誤って公開リポジトリへ push したキーは無効・再生成する**（履歴除去だけでは SHA 経由で残存しうるため）。

## 4. 制限が効いているかの確認（任意）
- 実機（正しい Bundle ID）でアプリから一覧取得が成功する。
- 同じキーを別アプリ/ブラウザから直接叩くと制限で弾かれる（iOSアプリ制限が効いている）。
