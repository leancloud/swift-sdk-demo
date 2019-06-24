//
//  FileViewController.swift
//  Chat
//
//  Created by ZapCannon87 on 2019/5/17.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit

class FileViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var url: URL?
    var handlerForData: ((Data) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "File"
        
        if let url = self.url {
            self.textView.text = ""
            self.activityIndicatorView.startAnimating()
            self.view.isUserInteractionEnabled = false
            var text: String? = url.lastPathComponent
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    text = String(data: data, encoding: .utf8)
                }
                mainQueueExecuting {
                    self.textView.text = text
                    self.activityIndicatorView.stopAnimating()
                    self.view.isUserInteractionEnabled = true
                }
            }
        } else {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .done,
                target: self,
                action: #selector(type(of: self).done)
            )
        }
    }
    
    @objc func done() {
        if let handler = self.handlerForData {
            if let text = self.textView.text, let data = text.data(using: .utf8) {
                handler(data)
            }
        }
        self.navigationController?.popViewController(animated: true)
    }
    
}
