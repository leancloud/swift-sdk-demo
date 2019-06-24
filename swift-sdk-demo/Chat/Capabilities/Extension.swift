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
    formatter.dateFormat = "MM'-'dd HH':'mm':'ss"
    formatter.timeZone = .current
    return formatter
}()

extension UIAlertController {
    
    static func show(error aError: Error, controller: UIViewController?) {
        self.show(error: "\(aError)", controller: controller)
    }
    
    static func show(error string: String, controller: UIViewController?) {
        mainQueueExecuting {
            let alert = UIAlertController(
                title: "Error",
                message: string,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            controller?.present(alert, animated: true)
        }
    }
    
}

extension UIImage {
    
    static func whiteImage(size: CGSize) -> UIImage? {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        UIColor.white.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    enum JPEGQuality: CGFloat {
        case lowest  = 0
        case low     = 0.25
        case medium  = 0.5
        case high    = 0.75
        case highest = 1
    }
    
    func jpeg(quality: JPEGQuality = .medium) -> Data? {
        return jpegData(compressionQuality: quality.rawValue)
    }
    
}
