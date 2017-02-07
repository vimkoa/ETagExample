//
//  ViewController.swift
//  ETagExample
//

import UIKit

class ViewController: UIViewController, NSURLConnectionDataDelegate {

    @IBOutlet var textView: UITextView?
    
    var etags = Dictionary<URL, String>()
    
    fileprivate var _dataTask: URLSessionDataTask?
    var dataTask: URLSessionDataTask? {
        get {
            return _dataTask
        }
        set {
            if newValue == nil {
                if (self.navigationItem.rightBarButtonItem != nil) {
                    let activityIndicatorView = self.navigationItem.rightBarButtonItem!.customView as! UIActivityIndicatorView
                    activityIndicatorView.stopAnimating()
                }
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Load", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ViewController.loadData))
            }
            else {
                let view = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
                view.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
                view.startAnimating()
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: view)
            }
            _dataTask = newValue
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataTask = nil
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func loadData() {
        
        if (self.dataTask != nil) {
            self.dataTask?.cancel()
        }
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = NSURLRequest.CachePolicy.reloadIgnoringCacheData
        let session = URLSession(configuration: config)
        
        let url = URL(string: "http://www.joywek.com/50x.html")!
        var request = URLRequest(url: url)
        if let tag = self.findTagByURL(url) {
            request.addValue(tag, forHTTPHeaderField: "If-None-Match")
        }
        self.dataTask = session.dataTask(with: request as URLRequest,
            completionHandler: { (data, response, error) -> Void in
                var text: String?
                if (data != nil) {
                    text = self.handleResponse(response!, data!, request)
                }
                else {
                    text = error?.localizedDescription
                }
                DispatchQueue.main.async(execute: {
                    self.textView?.text = text
                    self.dataTask = nil
                });
            })
        self.dataTask?.resume()
    }
    
    func handleResponse(_ response: URLResponse, _ data: Data, _ request: URLRequest) -> String? {
        if let resp = response as? HTTPURLResponse {
            if (resp.statusCode == 200) {
                self.etags[response.url!] = resp.allHeaderFields["Etag"] as? String
                let cachedResponse = CachedURLResponse(response: resp, data: data)
                URLCache.shared.storeCachedResponse(cachedResponse, for: request)
                return NSString(data: data, encoding: String.Encoding.utf8.rawValue) as? String
            }
            else if (resp.statusCode == 304) {
                if let cachedResponse = URLCache.shared.cachedResponse(for: request) {
                    return NSString(data: cachedResponse.data, encoding: String.Encoding.utf8.rawValue) as? String
                }
            }
            else {
                return HTTPURLResponse.localizedString(forStatusCode: resp.statusCode)
            }
        }
        return nil
    }
    
    func findTagByURL(_ url: URL) -> String? {
        return self.etags[url]
    }

}


