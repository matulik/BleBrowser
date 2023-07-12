//
//  JSRequest.swift
//  BleBrowser
//
//  Created by Paul Theriault on 15/03/2016.
//  Copyright © 2016 Stefan Arentz. All rights reserved.
//

import CoreBluetooth
import Foundation
import WebKit

class JSRequest {
    var id: Int
    var type: String
    var data: [String: AnyObject]
    var webView: WKWebView
    var resolved: Bool = false

    var deviceId: String {
        data["deviceId"] as? String ?? ""
    }

    var method: String {
        data["method"] as? String ?? ""
    }

    var args: [String] {
        data["args"] as? [String] ?? []
    }

    var origin: String {
        if let url = webView.url {
            return "\(String(describing: url.scheme)):\(url.host!):\(String(describing: url.port))"
        } else {
            return ""
        }
    }

    init(id: Int, type: String, data: [String: AnyObject], webView: WKWebView) {
        self.id = id
        self.type = type
        self.data = data
        self.webView = webView
    }

    func sendMessage(type: String, success: Bool, result: String, requestId: Int = -1) {
        if resolved {
            print("Warning: attempt to send a second  response to the same message")
            return
        }
        let commandString = "recieveMessage('\(type)', \(success), '\(result)',\(requestId))"
        print("-->:", commandString)
        webView.evaluateJavaScript(commandString, completionHandler: nil)
        resolved = true
    }
}
