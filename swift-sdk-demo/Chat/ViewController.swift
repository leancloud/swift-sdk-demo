//
//  ViewController.swift
//  swift-sdk-demo
//
//  Created by zapcannon87 on 2019/3/25.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import UIKit
import LeanCloud

class ViewController: UIViewController {

    @IBOutlet weak var inputClientIDButton: UIButton!
    @IBOutlet weak var usePreviousClientIDButton: UIButton!
    
    let storedClientIDDomain: String = "com.leancloud.swift.demo.chat.clientid"
    
    var previousClientID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.previousClientID = UserDefaults.standard.string(forKey: self.storedClientIDDomain)
        self.updateUsePreviousClientIDButtonEnabled()
    }
    
    @IBAction func inputClientIDAction(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Input a New Client ID",
            message: "The length of the ID should in range [1, 64], recommend using alphanumeric.",
            preferredStyle: .alert
        )
        alert.addTextField()
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { (action) in
            do {
                let ID = alert.textFields?.first?.text ?? ""
                Client.default.imClient = try IMClient(
                    ID: ID,
                    delegate: Client.default,
                    eventQueue: Client.default.queue
                )
                
                self.previousClientID = ID
                self.updateUsePreviousClientIDButtonEnabled()
                UserDefaults.standard.set(ID, forKey: self.storedClientIDDomain)
                
                UIApplication.shared.keyWindow?.rootViewController = TabBarController()
            } catch {
                UIAlertController.show(error: error, controller: self)
            }
        }))
        self.present(alert, animated: true)
    }
    
    @IBAction func usePreviousClientIDAction(_ sender: UIButton) {
        guard let previousClientID = self.previousClientID else {
            return
        }
        let alert = UIAlertController(
            title: "Use the Previous Client ID",
            message: "The previous client ID is \"\(previousClientID)\"",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { (action) in
            do {
                Client.default.imClient = try IMClient(
                    ID: previousClientID,
                    delegate: Client.default,
                    eventQueue: Client.default.queue
                )
                
                UIApplication.shared.keyWindow?.rootViewController = TabBarController()
            } catch {
                UIAlertController.show(error: error, controller: self)
            }
        }))
        self.present(alert, animated: true)
    }
    
    func updateUsePreviousClientIDButtonEnabled() {
        if let _ = self.previousClientID {
            self.usePreviousClientIDButton.isEnabled = true
            self.usePreviousClientIDButton.backgroundColor = .blue
        } else {
            self.usePreviousClientIDButton.isEnabled = false
            self.usePreviousClientIDButton.backgroundColor = .gray
        }
    }
}
