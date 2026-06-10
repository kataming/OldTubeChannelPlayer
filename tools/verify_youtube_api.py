# -*- coding: utf-8 -*-
"""
YouTube Data API v3 の動画一覧取得を、アプリと同じ流れでローカル確認するスクリプト。
（チャンネル解決 → uploads プレイリスト → 全ページ取得 → 公開日昇順=古い順に並べ替え）

アプリ本体(Swift)の YouTubeAPIClient と同じエンドポイント/パラメータを使うので、
これが通れば API キー・取得・古い順ソートの流れが妥当だと確認できます。

使い方（Windows / どこでも）:
    1) APIキーを用意（Resources/Config.plist に設定済みならそれを自動利用）
       または環境変数:  set YOUTUBE_API_KEY=あなたのキー   （PowerShellは $env:YOUTUBE_API_KEY="..."）
    2) python tools/verify_youtube_api.py "https://www.youtube.com/@ハンドル"

※ キーはこのスクリプト/ローカルでのみ使用します。コマンドラインに直接書くと履歴に残るため、
  Config.plist か環境変数での指定を推奨します。
"""
import json
import os
import sys
import urllib.parse
import urllib.request

API = "https://www.googleapis.com/youtube/v3"


def load_key():
    key = os.environ.get("YOUTUBE_API_KEY", "").strip()
    if key and key not in ("YOUR_API_KEY_HERE", "CI_DUMMY_KEY_FOR_BUILD"):
        return key
    # Resources/Config.plist から読む
    here = os.path.dirname(os.path.abspath(__file__))
    plist = os.path.join(here, "..", "Resources", "Config.plist")
    if os.path.exists(plist):
        try:
            import plistlib
            with open(plist, "rb") as f:
                d = plistlib.load(f)
            k = (d.get("YOUTUBE_API_KEY") or "").strip()
            if k and k not in ("YOUR_API_KEY_HERE", "CI_DUMMY_KEY_FOR_BUILD"):
                return k
        except Exception:
            pass
    return None


def get(path, params):
    url = API + "/" + path + "?" + urllib.parse.urlencode(params)
    try:
        with urllib.request.urlopen(url, timeout=20) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "ignore")
        raise SystemExit("APIエラー HTTP %s: %s" % (e.code, body[:300]))


def resolve_channel(inp, key):
    inp = inp.strip()
    base = {"part": "snippet,contentDetails", "key": key}
    if inp.startswith("@"):
        q = dict(base, forHandle=inp)
    elif inp.startswith("UC") and len(inp) == 24:
        q = dict(base, id=inp)
    else:
        comps = urllib.parse.urlparse(inp if "://" in inp else "https://" + inp)
        segs = [s for s in comps.path.split("/") if s]
        if not comps.netloc or "youtube.com" not in comps.netloc:
            raise SystemExit("YouTubeチャンネルURLとして認識できません: " + inp)
        if segs and segs[0] == "channel" and len(segs) > 1:
            q = dict(base, id=segs[1])
        elif segs and segs[0] == "user" and len(segs) > 1:
            q = dict(base, forUsername=segs[1])
        elif segs and segs[0].startswith("@"):
            q = dict(base, forHandle=segs[0])
        elif segs and segs[0] == "c" and len(segs) > 1:
            sid = search_channel(segs[1], key)
            q = dict(base, id=sid)
        elif segs:
            sid = search_channel(segs[0], key)
            q = dict(base, id=sid)
        else:
            raise SystemExit("チャンネルを特定できません: " + inp)
    data = get("channels", q)
    items = data.get("items", [])
    if not items:
        raise SystemExit("チャンネルが見つかりませんでした")
    it = items[0]
    return {
        "id": it["id"],
        "title": it["snippet"]["title"],
        "uploads": it["contentDetails"]["relatedPlaylists"]["uploads"],
    }


def search_channel(name, key):
    data = get("search", {"part": "snippet", "type": "channel", "q": name, "maxResults": 1, "key": key})
    items = data.get("items", [])
    if not items:
        raise SystemExit("検索でチャンネルが見つかりませんでした: " + name)
    return items[0]["id"]["channelId"]


def fetch_all(uploads, key):
    videos = []
    token = None
    pages = 0
    while True:
        q = {"part": "snippet,contentDetails", "playlistId": uploads, "maxResults": 50, "key": key}
        if token:
            q["pageToken"] = token
        data = get("playlistItems", q)
        for it in data.get("items", []):
            cd = it.get("contentDetails", {})
            sn = it.get("snippet", {})
            vid = cd.get("videoId") or sn.get("resourceId", {}).get("videoId")
            published = cd.get("videoPublishedAt") or sn.get("publishedAt") or ""
            if vid:
                videos.append({"id": vid, "title": sn.get("title", ""), "published": published})
        token = data.get("nextPageToken")
        pages += 1
        if not token or pages >= 100:
            break
    videos.sort(key=lambda v: v["published"])  # ISO8601文字列は昇順=古い順
    return videos


def main():
    key = load_key()
    if not key:
        raise SystemExit("APIキーが見つかりません。Resources/Config.plist か環境変数 YOUTUBE_API_KEY を設定してください。")
    inp = sys.argv[1] if len(sys.argv) > 1 else "https://www.youtube.com/@YouTube"
    print("チャンネル解決中: " + inp)
    ch = resolve_channel(inp, key)
    print("  -> %s (id=%s, uploads=%s)" % (ch["title"], ch["id"], ch["uploads"]))
    print("動画一覧を取得中...")
    vs = fetch_all(ch["uploads"], key)
    print("取得本数: %d（公開日昇順=古い順に並べ替え済み）" % len(vs))
    print("\n--- 最も古い5本 ---")
    for v in vs[:5]:
        print("  %s  %s  %s" % (v["published"][:10], v["id"], v["title"][:50]))
    print("\n--- 最も新しい5本 ---")
    for v in vs[-5:]:
        print("  %s  %s  %s" % (v["published"][:10], v["id"], v["title"][:50]))
    # 並びの妥当性チェック
    asc = all(vs[i]["published"] <= vs[i + 1]["published"] for i in range(len(vs) - 1))
    print("\n古い順ソート: " + ("OK" if asc else "NG"))


if __name__ == "__main__":
    main()
