//
//  ViewController.swift
//  swift-sdk-demo
//
//  Created by zapcannon87 on 2019/3/25.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import UIKit
import LeanCloud
import UserNotifications

var firstDidAppear: Bool = true

class ViewController: UIViewController {
    
    @IBOutlet weak var useLocalStorageSwitch: UISwitch!
    @IBOutlet weak var useLocalStorageLabel: UILabel!
    @IBOutlet weak var autoOpenSwitch: UISwitch!
    @IBOutlet weak var autoOpenLabel: UILabel!
    @IBOutlet weak var inputClientIDButton: UIButton!
    @IBOutlet weak var usePreviousClientIDButton: UIButton!
    
    enum Configuration: String {
        case storedClientIDDomain = "com.leancloud.swift.demo.chat.clientid"
        case storedUseLocalStorageOption = "com.leancloud.swift.demo.chat.uselocalstorage"
        case storedAutoOpenOption = "com.leancloud.swift.demo.chat.autoopen"
    }
    
    var previousClientID: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.previousClientID = UserDefaults.standard.string(forKey: Configuration.storedClientIDDomain.rawValue)
        if let _ = self.previousClientID {
            self.usePreviousClientIDButton.isEnabled = true
            self.usePreviousClientIDButton.backgroundColor = .blue
        } else {
            self.usePreviousClientIDButton.isEnabled = false
            self.usePreviousClientIDButton.backgroundColor = .gray
        }
        
        self.useLocalStorageSwitch.isOn = UserDefaults.standard.bool(forKey: Configuration.storedUseLocalStorageOption.rawValue)
        self.useLocalStorageAction(self.useLocalStorageSwitch)
        
        self.autoOpenSwitch.isOn = (self.previousClientID != nil)
            ? UserDefaults.standard.bool(forKey: Configuration.storedAutoOpenOption.rawValue)
            : false
        self.autoOpenAction(self.autoOpenSwitch)
        
        self.view.isUserInteractionEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            switch settings.authorizationStatus {
            case .authorized:
                mainQueueExecuting {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
                    if granted {
                        mainQueueExecuting {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    } else if let error = error {
                        UIAlertController.show(error: error, controller: self)
                    }
                }
            default:
                break
            }
        }
        
        if firstDidAppear {
            firstDidAppear = false
            if let ID = self.previousClientID, self.autoOpenSwitch.isOn {
                do {
                    try self.changeRootViewControllerToTabBarController(ID: ID)
                } catch {
                    UIAlertController.show(error: error, controller: self)
                }
            }
        }
        
        self.view.isUserInteractionEnabled = true
    }
    
    @IBAction func useLocalStorageAction(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: Configuration.storedUseLocalStorageOption.rawValue)
        UserDefaults.standard.synchronize()
        if sender.isOn {
            self.useLocalStorageLabel.text = "Use Local Storage"
        } else {
            self.useLocalStorageLabel.text = "Not Use Local Storage"
        }
    }
    
    @IBAction func autoOpenAction(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: Configuration.storedAutoOpenOption.rawValue)
        UserDefaults.standard.synchronize()
        if sender.isOn {
            self.autoOpenLabel.text = "Auto Open after Launching"
        } else {
            self.autoOpenLabel.text = "Not Auto Open after Launching"
        }
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
                let ID: String = alert.textFields?.first?.text ?? ""
                try self.changeRootViewControllerToTabBarController(ID: ID)
                UserDefaults.standard.set(ID, forKey: Configuration.storedClientIDDomain.rawValue)
                UserDefaults.standard.synchronize()
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
                try self.changeRootViewControllerToTabBarController(ID: previousClientID)
            } catch {
                UIAlertController.show(error: error, controller: self)
            }
        }))
        self.present(alert, animated: true)
    }
    
    func changeRootViewControllerToTabBarController(ID: String) throws {
        let options: IMClient.Options = self.useLocalStorageSwitch.isOn
            ? [.receiveUnreadMessageCountAfterSessionDidOpen, .usingLocalStorage]
            : [.receiveUnreadMessageCountAfterSessionDidOpen]
        
        Client.default.imClient = try IMClient(
            ID: ID,
            options: options,
            delegate: Client.default,
            eventQueue: Client.default.queue
        )
        
        UIApplication.shared.keyWindow?.rootViewController = TabBarController()
    }
    
}
