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
        
        do {
            LCApplication.logLevel = .all
            var config = LCApplication.Configuration()
            config.isObjectRawDataAtomic = true
            try LCApplication.default.set(
                id: "6HKynQEeIYeWpHmF9e7ocY5R-TeStHjQi",
                key: "FLx5kVKBU04k6SxmuIVndMNy",
                serverURL: "https://api.uc-test1.leancloud.cn",
                configuration: config)
        } catch {
            fatalError("\(error)")
        }
        
        // init
        _ = LCApplication.default.currentInstallation
        _ = Client.delegator
        _ = LocationManager.delegator
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = UINavigationController(rootViewController: LaunchViewController())
        self.window?.makeKeyAndVisible()
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Client.installationOperatingQueue.async {
            let installation = LCApplication.default.currentInstallation
            installation.set(deviceToken: deviceToken, apnsTeamId: "7J5XFNL99Q")
            if let error = installation.save().error {
                print(error)
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
    
}
