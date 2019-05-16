//
//  FileSampleViewController.swift
//  Chat
//
//  Created by ZapCannon87 on 2019/5/17.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit

class FileSampleViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    
    var handlerForData: ((Data) -> Void)?
    var url: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url = self.url {
            
            self.textView.text = ""
            self.activityIndicatorView.startAnimating()
            self.view.isUserInteractionEnabled = false
            
            var text: String? = "-"
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
        }
    }
    
    @IBAction func cancelAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneAction(_ sender: UIButton) {
        if let handler = self.handlerForData {
            if let text = self.textView.text, let data = text.data(using: .utf8) {
                handler(data)
            }
        }
        self.dismiss(animated: true, completion: nil)
    }
    
}
