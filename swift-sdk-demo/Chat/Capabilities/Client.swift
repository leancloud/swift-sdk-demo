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
    
    static let queue = DispatchQueue(label: "\(Client.self).queue")
    
    static let installationOperatingQueue = DispatchQueue(label: "\(Client.self).installationOperatingQueue", qos: .background)
    
    static var current: IMClient!
    
    static var observerMap: [String: (IMClient, IMConversation, IMConversationEvent) -> Void] = [:]
    
    static func addObserver(key: String, closure: @escaping (IMClient, IMConversation, IMConversationEvent) -> Void) {
        self.queue.async {
            self.observerMap[key] = closure
        }
    }
    
    static func removeObserver(key: String) {
        self.queue.async {
            self.observerMap.removeValue(forKey: key)
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
    }
    
    func client(_ client: IMClient, conversation: IMConversation, event: IMConversationEvent) {
        Client.specificAssertion
        for item in Client.observerMap.values {
            item(client, conversation, event)
        }
    }
    
}
