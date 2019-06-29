//
//  Client.swift
//  Chat
//
//  Created by zapcannon87 on 2019/3/27.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class Client {
    
    #if DEBUG
    static let specificKey = DispatchSpecificKey<Int>()
    static let specificValue: Int = Int.random(in: 1...999)
    #endif
    static var specificAssertion: Void {
        #if DEBUG
        assert(self.specificValue == DispatchQueue.getSpecific(key: self.specificKey))
        #endif
    }
    
    static var storedConversations: [IMConversation]?
    static var storedServiceConversations: [IMServiceConversation]?
    
    static let queue = DispatchQueue(label: "\(Client.self).queue")
    
    static let installationOperatingQueue = DispatchQueue(label: "\(Client.self).installationOperatingQueue", qos: .background)
    
    static var current: IMClient!
    
    static var sessionObserverMap: [String: (IMClient, IMClientEvent) -> Void] = [:]
    
    static var eventObserverMap: [String: (IMClient, IMConversation, IMConversationEvent) -> Void] = [:]
    
    static func addEventObserver(key: String, closure: @escaping (IMClient, IMConversation, IMConversationEvent) -> Void) {
        self.queue.async {
            self.eventObserverMap[key] = closure
        }
    }
    
    static func removeEventObserver(key: String) {
        self.queue.async {
            self.eventObserverMap.removeValue(forKey: key)
        }
    }
    
    static func addSessionObserver(key: String, closure: @escaping (IMClient, IMClientEvent) -> Void) {
        self.queue.async {
            self.sessionObserverMap[key] = closure
        }
    }
    
    static func removeSessionObserver(key: String) {
        self.queue.async {
            self.sessionObserverMap.removeValue(forKey: key)
        }
    }
    
    static let delegator = Client()
    
    private init() {
        #if DEBUG
        Client.queue.setSpecific(key: Client.specificKey, value: Client.specificValue)
        #endif
    }
    
}

extension Client: IMClientDelegate {
    
    func client(_ client: IMClient, event: IMClientEvent) {
        Client.specificAssertion
        switch event {
        case .sessionDidClose(error: let error):
            let showSessionClose: (String) -> Void = { message in
                mainQueueExecuting {
                    let alert = UIAlertController(title: "Session Closed", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                        Client.current = nil
                        Configuration.UserOption.isAutoOpenEnabled.set(value: false)
                        UIApplication.shared.keyWindow?.rootViewController = UINavigationController(rootViewController: LaunchViewController())
                    }))
                    UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
                }
                Client.installationOperatingQueue.async {
                    do {
                        let installation = LCApplication.default.currentInstallation
                        try installation.remove("channels", element: client.ID)
                        if let _ = installation.deviceToken {
                            if let error = installation.save().error {
                                print(error)
                            }
                        }
                    } catch {
                        print(error)
                    }
                }
            }
            switch error.code {
            case 4111:
                showSessionClose("Session Conflict")
            case 4115:
                showSessionClose("Session Kicked By API")
            default:
                showSessionClose("code: \(error.code), reason: \(error.reason ?? "")")
            }
        default:
            for ob in Client.sessionObserverMap.values {
                ob(client, event)
            }
        }
    }
    
    func client(_ client: IMClient, conversation: IMConversation, event: IMConversationEvent) {
        Client.specificAssertion
        for item in Client.eventObserverMap.values {
            item(client, conversation, event)
        }
    }
    
}
