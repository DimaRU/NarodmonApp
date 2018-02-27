//
//  MapViewController
//
//
//  Created by Dmitriy Borovikov on 26.02.2018.
//  Copyright © 2018 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import WebKit
import JavaScriptCore


class MapViewController: NSViewController, WKUIDelegate, WKScriptMessageHandler {

    var delegate: DeviceIdDelegate? = nil
    @IBOutlet weak var mapView: NSView!
    
    var webView: WKWebView!
    let url = URL(string: NSLocalizedString("https://narodmon.ru", comment: "Map View url"))!
    let handlerName = "narodmonbarHandler"
    let shareScript: String = """
window.addEventListener("load", whenPageFullyLoaded, false);
function whenPageFullyLoaded(e) {
 ShareLink = function(id) {
    alert('hello');
    window.webkit.messageHandlers.narodmonbarHandler.postMessage(id);
 }
}
"""

    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()

        let request = URLRequest(url: url)
        webView.load(request)
      
    }
    
    override func viewWillAppear() {
        view.window?.title = url.absoluteString
        view.window?.styleMask = [.titled, .closable, .resizable, .unifiedTitleAndToolbar]
    }

    func setupWebView() {
        let webConfiguration = WKWebViewConfiguration()
        let contentController = WKUserContentController()
        
        let userScript = WKUserScript(source: shareScript, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: false)
        contentController.removeAllUserScripts()
        contentController.addUserScript(userScript)
        contentController.add(self, name: handlerName)
        
        webConfiguration.userContentController = contentController
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self

        webView.translatesAutoresizingMaskIntoConstraints = false
        mapView.addSubview(webView)
        webView.leadingAnchor.constraint(equalTo: mapView.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: mapView.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: mapView.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: mapView.bottomAnchor).isActive = true
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == handlerName {
            if let number = message.body as? NSNumber {
                let deviceId = number.intValue
                nextTick {
                    self.delegate?.add(device: deviceId)
                }
            }
        }
    }
}
