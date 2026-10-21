import SwiftUI
import WebKit

public struct CraftYouTubePlayerView: UIViewRepresentable {
    public let videoId: String
    public let bridgeHolder: YouTubeBridgeHolder
    public let onMessage: @MainActor (YouTubePlayerBridgeMessage) -> Void

    public init(
        videoId: String,
        bridgeHolder: YouTubeBridgeHolder,
        onMessage: @escaping @MainActor (YouTubePlayerBridgeMessage) -> Void
    ) {
        self.videoId = videoId
        self.bridgeHolder = bridgeHolder
        self.onMessage = onMessage
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onMessage: onMessage)
    }

    public func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        let contentController = configuration.userContentController
        contentController.add(context.coordinator, name: "shadowingBridge")

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.isScrollEnabled = false
        webView.isOpaque = false
        webView.backgroundColor = .black

        bridgeHolder.webView = webView
        let html = YouTubePlayerBridgeScript.htmlTemplate(videoId: videoId)
        webView.loadHTMLString(html, baseURL: URL(string: "https://www.youtube.com"))
        return webView
    }

    public func updateUIView(_ uiView: WKWebView, context: Context) {}

    public static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "shadowingBridge")
    }

    public final class Coordinator: NSObject, WKScriptMessageHandler {
        private let onMessage: @MainActor (YouTubePlayerBridgeMessage) -> Void

        public init(onMessage: @escaping @MainActor (YouTubePlayerBridgeMessage) -> Void) {
            self.onMessage = onMessage
        }

        public func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard let dict = message.body as? [String: Any] else { return }
            let parsed = YouTubePlayerBridgeMessage(dictionary: dict)
            Task { @MainActor in
                onMessage(parsed)
            }
        }
    }
}

@MainActor
public final class YouTubeBridgeHolder {
    fileprivate weak var webView: WKWebView?

    public init() {}

    public func playSegment(start: Double, end: Double, rate: Float = 1.0) {
        let script = "playSegment(\(start.description), \(end.description), \(rate.description));"
        webView?.evaluateJavaScript(script)
    }

    public func pauseVideo() {
        let script = "pauseVideo();"
        webView?.evaluateJavaScript(script)
    }

    public func replaySegment(start: Double, end: Double, rate: Float = 1.0) {
        playSegment(start: start, end: end, rate: rate)
    }
}
