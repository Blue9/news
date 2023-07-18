//
//  ContentView.swift
//  news
//
//  Created by Gautam Mekkat on 7/16/23.
//

import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject var model = WebViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    HStack {
                        TextField("URL", text: $model.urlString)
                            .keyboardType(.URL)
                            .autocapitalization(.none)
                            .padding(10)
                        Spacer()
                    }
                    .background(Color.white)
                    .cornerRadius(30)

                    Button("Go", action: model.loadUrl)
                        .foregroundColor(.white)
                        .padding(10)

                }
                .padding(10)
                .background(Color.gray)

                WebView(webView: model.webView)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: model.goBack) {
                    Image(systemName: "arrowshape.turn.up.backward")
                }.disabled(!model.canGoBack)

                Button(action: model.goForward) {
                    Image(systemName: "arrowshape.turn.up.right")
                }.disabled(!model.canGoForward)

                Spacer()
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let webView: WKWebView

    func makeUIView(context: Context) -> WKWebView {
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
    }
}

class WebViewModel: NSObject, ObservableObject, WKNavigationDelegate {
    let webView: WKWebView
    @Published var urlString: String = "https://www.ft.com"
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var javascriptEnabled = false

    override init() {
        self.webView = WebViewModel.initWebView()
        super.init()
        self.webView.navigationDelegate = self
        self.setupBindings()
        self.loadUrl()
    }

    func loadUrl() {
        guard let url = URL(string: urlString) else {
            return
        }
        var request = URLRequest(url: url)
        request.setValue("https://www.google.com", forHTTPHeaderField: "Referer")
        request.httpShouldHandleCookies = false
        webView.load(request)
    }

    func goForward() {
        webView.goForward()
    }

    func goBack() {
        webView.goBack()
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        var request = navigationAction.request // creates new request object
        if navigationAction.navigationType == .linkActivated && request.value(forHTTPHeaderField: "Referer") != "https://www.google.com" {
            request.setValue("https://www.google.com", forHTTPHeaderField: "Referer")
            request.setValue("FTCookieConsentGDPR=true; ft-access-decision-policy=FLEX_PRIVILEGED_REFERER_POLICY; ft-privileged-referer-model=1; ft-privileged-referer-phase=S;", forHTTPHeaderField: "Cookie")
            decisionHandler(.cancel)
            webView.load(request)
        } else {
            decisionHandler(.allow)
        }
    }

    private func setupBindings() {
        webView.publisher(for: \.canGoBack).assign(to: &$canGoBack)
        webView.publisher(for: \.canGoForward).assign(to: &$canGoForward)
    }

    private static func initWebView() -> WKWebView {
        let script = WKUserScript(source: SCRIPT, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let config = WKWebViewConfiguration()
        config.userContentController.addUserScript(script)
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Chrome/41.0.2272.96 Mobile Safari/537.36 (compatible ; Googlebot/2.1 ; +http://www.google.com/bot.html)"
        return webView
    }
}

let SCRIPT = """
const handleNytimes = () => {
  window.localStorage.clear()
  setInterval(() => {
    const banners = document.querySelectorAll('div[data-testid="inline-message"], div[id^="ad-"], div.expanded-dock, div.pz-ad-box')
    banners.forEach(e => e.remove())
    document.querySelectorAll('#gateway-content, #standalone-footer, .css-gx5sib').forEach(e => e.remove())
    document.querySelector(".css-mcm29f").className = ''
    document.querySelector('#site-content').style = 'position: relative !important'
  }, 1000)
}

const handleWsj = () => {
  if (window.location.href.includes('/amp/')) {
    document.querySelectorAll(
      '[subscriptions-section="content-not-granted"], [subscriptions-display="NOT granted"]'
    ).forEach(e => e.remove())

    document.querySelectorAll(
      '[subscriptions-section="content"], [subscriptions-display="granted"]'
    ).forEach(e => { e.style = 'display: block !important' })
  } else {
    let articlePath = window.location.href.slice(20)
    if (articlePath) {
      window.location.href = 'https://www.wsj.com/amp/' + articlePath
    }
  }
}

const handleFt = () => {
  setInterval(() => {
    window.localStorage.clear()
    window.sessionStorage.clear()
    document.querySelector('.n-messaging-slot')?.remove()
    document.querySelector('.js-article-ribbon')?.remove()
    document.querySelector('.o-ads')?.remove()
  }, 1000)
}

switch (window.location.host) {
case 'www.wsj.com': handleWsj()
case 'www.nytimes.com': handleNytimes()
case 'www.ft.com': handleFt()
}
"""
