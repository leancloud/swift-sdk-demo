//
//  AppDelegate.swift
//  swift-sdk-demo
//
//  Created by zapcannon87 on 2019/3/25.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import UIKit
import LeanCloud

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        LCApplication.logLevel = .all
        do {
            try LCApplication.default.set(
                id: "heQFQ0SwoQqiI3gEAcvKXjeR-gzGzoHsz",
                key: "lNSjPPPDohJjYMJcQSxi9qAm"
            )
            return true
        } catch {
            print(error)
            return false
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Client.default.installationSavingQueue.async {
            LCApplication.default.currentInstallation.set(
                deviceToken: deviceToken,
                apnsTeamId: "7J5XFNL99Q"
            )
            if let error = LCApplication.default.currentInstallation.save().error {
                print(error)
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }

}
