import SwiftUI
import WebKit

/// YouTube IFrame Player API のプレイヤー状態。
enum YouTubePlayerState: Int {
    case unstarted = -1
    case ended = 0
    case playing = 1
    case paused = 2
    case buffering = 3
    case cued = 5
}

/// 公式の YouTube IFrame Player API を WKWebView で表示する。
/// 動画ファイルの直接再生・ダウンロードは行わず、公式プレイヤーをそのまま埋め込む。
struct YouTubePlayerWebView: UIViewRepresentable {
    let videoId: String
    /// 初回読み込み後に自動再生するか。false の場合は cue のみ（自動再生しない）。
    var autoplayOnLoad: Bool = false
    var onStateChange: ((YouTubePlayerState) -> Void)? = nil

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let controller = WKUserContentController()
        controller.add(context.coordinator, name: "ytHandler")

        let config = WKWebViewConfiguration()
        config.userContentController = controller
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black

        context.coordinator.webView = webView
        context.coordinator.loadedVideoId = videoId
        webView.loadHTMLString(Self.html(videoId: videoId),
                               baseURL: URL(string: "https://www.youtube.com"))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // videoId が変わったときだけ JS で差し替える。
        guard context.coordinator.loadedVideoId != videoId else { return }
        context.coordinator.loadedVideoId = videoId
        let fn = autoplayOnLoad ? "loadVideo" : "cueVideo"
        webView.evaluateJavaScript("\(fn)('\(Self.escape(videoId))');", completionHandler: nil)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.configuration.userContentController.removeScriptMessageHandler(forName: "ytHandler")
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let parent: YouTubePlayerWebView
        weak var webView: WKWebView?
        var loadedVideoId: String?

        init(_ parent: YouTubePlayerWebView) { self.parent = parent }

        func userContentController(_ userContentController: WKUserContentController,
                                   didReceive message: WKScriptMessage) {
            guard message.name == "ytHandler",
                  let body = message.body as? [String: Any],
                  let event = body["event"] as? String else { return }
            switch event {
            case "state":
                if let raw = body["state"] as? Int,
                   let state = YouTubePlayerState(rawValue: raw) {
                    parent.onStateChange?(state)
                }
            case "ended":
                parent.onStateChange?(.ended)
            default:
                break
            }
        }
    }

    /// videoId に紛れ込みうる引用符等を最低限エスケープする。
    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "")
         .replacingOccurrences(of: "'", with: "")
    }

    private static func html(videoId: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0, user-scalable=no"/>
        <style>
          * { margin: 0; padding: 0; }
          html, body { background: #000; height: 100%; overflow: hidden; }
          #player { position: absolute; top: 0; left: 0; width: 100%; height: 100%; }
        </style>
        </head>
        <body>
        <div id="player"></div>
        <script src="https://www.youtube.com/iframe_api"></script>
        <script>
          var player;
          var pendingId = '\(escape(videoId))';
          function onYouTubeIframeAPIReady() {
            player = new YT.Player('player', {
              width: '100%', height: '100%',
              videoId: pendingId,
              playerVars: { playsinline: 1, rel: 0, modestbranding: 1, fs: 1 },
              events: { 'onStateChange': onStateChange }
            });
          }
          function onStateChange(e) { post({ event: 'state', state: e.data }); }
          function post(msg) {
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.ytHandler) {
              window.webkit.messageHandlers.ytHandler.postMessage(msg);
            }
          }
          function loadVideo(id) { if (player && player.loadVideoById) { player.loadVideoById(id); } }
          function cueVideo(id) { if (player && player.cueVideoById) { player.cueVideoById(id); } }
          function playVideo() { if (player && player.playVideo) { player.playVideo(); } }
          function pauseVideo() { if (player && player.pauseVideo) { player.pauseVideo(); } }
        </script>
        </body>
        </html>
        """
    }
}
