//
//  AppDelegate.swift
//  VoIP
//
//  Created by zapcannon87 on 2019/11/26.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import UIKit
import UserNotifications
import LeanCloud

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    static let installationQueue = DispatchQueue(label: "installation")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        do {
            LCApplication.logLevel = .all
            try LCApplication.default.set(
                id: "jenSt9nvWtuJtmurdE28eg5M-MdYXbMMI",
                key: "8VLPsDlskJi8KsKppED4xKS0")
        } catch {
            fatalError("\(error)")
        }
        
        self.registerForMessagePushes()
        
        return true
    }
    
    func registerForMessagePushes() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .authorized:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(
                options: [.badge, .alert, .sound]) { (granted, error) in
                    if granted {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    } else if let error = error {
                        print(error)
                    }
                }
            default:
                break
            }
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        AppDelegate.installationQueue.async {
            let installation = LCApplication.default.currentInstallation
            installation.set(
                deviceToken: deviceToken,
                apnsTeamId: "7J5XFNL99Q")
            let result = installation.save()
            if let error = result.error {
                print(error)
            }
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("didFailToRegisterForRemoteNotificationsWithError: \(error)")
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

