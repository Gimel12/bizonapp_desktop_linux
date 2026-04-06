import QtQuick
import QtWebEngine
import components

WebEngineView {
    id: webView

    // Call this to navigate — avoids setting url to "" on chat tab
    function loadUrl(newUrl) {
        if (newUrl && newUrl !== "") {
            webView.url = newUrl;
        }
    }

    backgroundColor: Theme.bgPrimary

    settings.javascriptEnabled: true
    settings.pluginsEnabled: true
    settings.localContentCanAccessRemoteUrls: true
    settings.dnsPrefetchEnabled: true

    profile.httpUserAgent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

    onNewWindowRequested: function(request) {
        webView.url = request.requestedUrl;
    }
}
