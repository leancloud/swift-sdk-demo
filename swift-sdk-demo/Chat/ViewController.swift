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
    
    @IBAction func inputClientIDAction(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Input your Client-ID",
            message: "The length of Client-ID should in range [1, 64].",
            preferredStyle: .alert
        )
        alert.addTextField()
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { (action) in
            do {
                Client.default.imClient = try IMClient(
                    ID: alert.textFields?.first?.text ?? "",
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
    
}

extension UIAlertController {
    
    static func show(error aError: Error, controller: UIViewController) {
        self.show(error: "\(aError)", controller: controller)
    }
    
    static func show(error string: String, controller: UIViewController) {
        mainQueueExecuting {
            let alert = UIAlertController(
                title: "Error",
                message: string,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            controller.present(alert, animated: true)
        }
    }
    
}

func mainQueueExecuting(_ closure: @escaping () -> Void) {
    if Thread.isMainThread {
        closure()
    } else {
        DispatchQueue.main.async {
            closure()
        }
    }
}
