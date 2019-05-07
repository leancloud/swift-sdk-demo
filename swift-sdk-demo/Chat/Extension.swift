//
//  Extension.swift
//  Chat
//
//  Created by zapcannon87 on 2019/5/5.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit

func mainQueueExecuting(_ closure: @escaping () -> Void) {
    if Thread.isMainThread {
        closure()
    } else {
        DispatchQueue.main.async {
            closure()
        }
    }
}

let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"
    formatter.timeZone = .current
    return formatter
}()

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
