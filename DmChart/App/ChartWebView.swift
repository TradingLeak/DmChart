import SwiftUI
import UIKit
import WebKit

final class ChartWebViewModel: ObservableObject {
    @Published private(set) var isLoading = true
    @Published private(set) var progress: Double = 0.04
    @Published private(set) var canGoBack = false
    @Published private(set) var canGoForward = false
    @Published private(set) var hasLoadedPage = false
    @Published private(set) var currentURL: URL?
    @Published private(set) var loadError: String?

    private weak var webView: WKWebView?

    func attach(_ webView: WKWebView) {
        self.webView = webView
        updateNavigationState(from: webView)
    }

    func goBack() {
        webView?.goBack()
    }

    func goForward() {
        webView?.goForward()
    }

    func reload() {
        loadError = nil
        isLoading = true
        progress = 0.04
        if let webView, webView.url != nil {
            webView.reload()
        } else {
            loadHomePage()
        }
    }

    func openCurrentPageInBrowser() {
        guard let currentURL else { return }
        UIApplication.shared.open(currentURL, options: [:], completionHandler: nil)
    }

    fileprivate func loadHomePage() {
        guard let url = URL(string: "https://dmcharts.com/chart") else { return }
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 60)
        webView?.load(request)
    }

    fileprivate func navigationDidStart() {
        isLoading = true
        progress = 0.04
        loadError = nil
    }

    fileprivate func updateProgress(_ value: Double) {
        progress = min(max(value, 0.04), 1.0)
    }

    fileprivate func navigationDidFinish(_ webView: WKWebView) {
        isLoading = false
        progress = 1
        hasLoadedPage = true
        loadError = nil
        updateNavigationState(from: webView)
    }

    fileprivate func navigationDidFail(_ error: Error, webView: WKWebView) {
        let nsError = error as NSError
        guard nsError.code != NSURLErrorCancelled else { return }

        isLoading = false
        progress = 0
        updateNavigationState(from: webView)
        if !hasLoadedPage {
            loadError = "Kiểm tra kết nối internet rồi thử lại."
        }
    }

    fileprivate func updateNavigationState(from webView: WKWebView) {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        currentURL = webView.url
    }
}

struct ChartWebView: UIViewRepresentable {
    @ObservedObject var model: ChartWebViewModel

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.isOpaque = false
        webView.backgroundColor = UIColor(
            red: 10.0 / 255.0,
            green: 15.0 / 255.0,
            blue: 28.0 / 255.0,
            alpha: 1.0
        )
        webView.scrollView.backgroundColor = webView.backgroundColor
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.keyboardDismissMode = .interactive

        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = .systemTeal
        refreshControl.addTarget(context.coordinator, action: #selector(Coordinator.refreshPage), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl

        context.coordinator.webView = webView
        context.coordinator.refreshControl = refreshControl
        context.coordinator.observeProgress(of: webView)
        model.attach(webView)
        model.loadHomePage()
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // Navigation is driven by native controls and WKWebView delegates.
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        coordinator.progressObservation?.invalidate()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private let model: ChartWebViewModel
        weak var webView: WKWebView?
        weak var refreshControl: UIRefreshControl?
        var progressObservation: NSKeyValueObservation?

        init(model: ChartWebViewModel) {
            self.model = model
        }

        func observeProgress(of webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] observedWebView, _ in
                DispatchQueue.main.async {
                    self?.model.updateProgress(observedWebView.estimatedProgress)
                }
            }
        }

        @objc func refreshPage() {
            webView?.reload()
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            model.navigationDidStart()
            model.updateNavigationState(from: webView)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            refreshControl?.endRefreshing()
            model.navigationDidFinish(webView)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            refreshControl?.endRefreshing()
            model.navigationDidFail(error, webView: webView)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            refreshControl?.endRefreshing()
            model.navigationDidFail(error, webView: webView)
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url,
                  let scheme = url.scheme?.lowercased() else {
                decisionHandler(.allow)
                return
            }

            switch scheme {
            case "http", "https", "about", "data", "blob":
                decisionHandler(.allow)
            default:
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
            }
        }

        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            // Keep target="_blank" links in this app instead of creating an empty popup.
            guard navigationAction.targetFrame == nil else { return nil }
            webView.load(navigationAction.request)
            return nil
        }
    }
}
