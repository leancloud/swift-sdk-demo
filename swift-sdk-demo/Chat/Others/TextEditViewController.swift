//
//  TextEditViewController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/6/23.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit

class TextEditViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    
    var text: String?
    var handlerForEditedText: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Text Editing"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(type(of: self).done)
        )
        self.textView.text = self.text
    }
    
    @objc func done() {
        self.handlerForEditedText?(self.textView.text)
        self.navigationController?.popViewController(animated: true)
    }
    
}
