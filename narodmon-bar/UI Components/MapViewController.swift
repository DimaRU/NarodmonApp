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

    var delegate: (DeviceIdDelegate & CameraIdDelegate)? = nil

    var titlebarViewController: NSTitlebarAccessoryViewController!
    var webView: WKWebView!
    let url = URL(string: NSLocalizedString("https://narodmon.com", comment: "Map View url"))!
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
        titlebarViewController = (NSStoryboard.main?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "MapTitlebarViewController")) as! NSTitlebarAccessoryViewController)
        titlebarViewController.layoutAttribute = .left

        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    override func viewWillAppear() {
        guard let window = view.window else { return }
        window.styleMask = [.titled, .closable, .resizable, .unifiedTitleAndToolbar]
        //window.titlebarAppearsTransparent = true
        window.title = ""
        view.window?.addTitlebarAccessoryViewController(titlebarViewController)
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
        view.addSubview(webView)
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == handlerName, let url = message.body as? String else {
            return
        }
        let urlParts = url.split(separator: "/")
        guard urlParts.count == 2, let deviceId = Int(urlParts[1]) else {
            return
        }
        nextTick {
            if deviceId > 0 {
                self.delegate?.add(device: deviceId)
            } else {
                self.delegate?.add(camera: -deviceId)
            }
        }
    }
}
