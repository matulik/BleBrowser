import UIKit
import WebKit

class ViewController: UIViewController, UITextFieldDelegate, WKNavigationDelegate, WKUIDelegate {
    @IBOutlet var locationTextField: UITextField!
    @IBOutlet var containerView: UIView!

    var devicePicker: PopUpPickerView!

    var webView: WKWebView!
    var webBluetoothManager: WebBluetoothManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        locationTextField.delegate = self

        // load polyfill script
        var script: String?
        if let filePath: String = Bundle(for: ViewController.self).path(forResource: "WebBluetooth", ofType: "js") {
            do {
                script = try NSString(contentsOfFile: filePath, encoding: NSUTF8StringEncoding) as String
            } catch _ {
                print("Error loading polyfil")
                return
            }
        }

        // create bluetooth object, and set it to listen to messages
        webBluetoothManager = WebBluetoothManager()
        let webCfg = WKWebViewConfiguration()
        let userController = WKUserContentController()
        userController.add(webBluetoothManager, name: "bluetooth")

        // connect picker
        devicePicker = PopUpPickerView()
        devicePicker.delegate = webBluetoothManager
        view.addSubview(devicePicker)
        webBluetoothManager.devicePicker = devicePicker

        // add the bluetooth script prior to loading all frames
        let userScript = WKUserScript(source: script!, injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: false)
        userController.addUserScript(userScript)
        webCfg.userContentController = userController

        webView = WKWebView(
            frame: containerView.bounds,
            configuration: webCfg
        )
        webView.uiDelegate = self

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = self
        containerView.addSubview(webView)

        let views = ["webView": webView]
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[webView]|",
                                                                    options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: views))
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[webView]|",
                                                                    options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: views))

        loadLocation(var: "https://pauljt.github.io/bletest/")
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        loadLocation(var: textField.text!)
        return true
    }

    func loadLocation(`var` location: String) {
        var location = location
        if !location.hasPrefix("http://"), !location.hasPrefix("https://") {
            location = "http://" + location
        }
        locationTextField.text = location
        webView.load(NSURLRequest(url: NSURL(string: location)! as URL) as URLRequest)
    }

    func webView(_ webView: WKWebView, didFinish _: WKNavigation!) {
        locationTextField.text = webView.url?.absoluteString
    }

    func webView(_ webView: WKWebView, didFail _: WKNavigation!, withError error: Error) {
        locationTextField.text = webView.url?.absoluteString
        webView.loadHTMLString("<p>Fail Navigation: \(error.localizedDescription)</p>", baseURL: nil)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation _: WKNavigation!, withError error: Error) {
        locationTextField.text = webView.url?.absoluteString
        webView.loadHTMLString("<p>Fail Provisional Navigation: \(error.localizedDescription)</p>", baseURL: nil)
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("webView:\(webView) runJavaScriptAlertPanelWithMessage:\(message) initiatedByFrame:\(frame) completionHandler:\(completionHandler)")

        let alertController = UIAlertController(title: frame.request.url?.host, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completionHandler()
        }))
        present(alertController, animated: true, completion: nil)
    }
}
