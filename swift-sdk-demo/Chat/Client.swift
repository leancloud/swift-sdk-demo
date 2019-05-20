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
    
    static let `default` = Client()
    
    let queue = DispatchQueue(label: "\(Client.self).queue")
    let installationSavingQueue = DispatchQueue(label: "\(Client.self).installationSavingQueue", qos: .background)
    
    #if DEBUG
    let specificKey = DispatchSpecificKey<Int>()
    let specificValue: Int = Int.random(in: 1...999)
    #endif
    var specificAssertion: Void {
        #if DEBUG
        assert(self.specificValue == DispatchQueue.getSpecific(key: self.specificKey))
        #endif
    }
    
    var imClient: IMClient!
    
    private var observerMap: [String: (IMClient, IMConversation, IMConversationEvent) -> Void] = [:]
    
    private init() {
        #if DEBUG
        self.queue.setSpecific(key: self.specificKey, value: self.specificValue)
        #endif
    }
    
    lazy var sessionStatusView: SessionStatusView = {
        let view = UINib(nibName: "SessionStatusView", bundle: .main)
            .instantiate(withOwner: nil).first as! SessionStatusView
        if let keyWindow: UIWindow = UIApplication.shared.keyWindow {
            keyWindow.addSubview(view)
            view.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: keyWindow.frame.height)
        }
        return view
    }()
    
    func addObserver(key: String, closure: @escaping (IMClient, IMConversation, IMConversationEvent) -> Void) {
        self.queue.async {
            self.observerMap[key] = closure
        }
    }
    
    func removeObserver(key: String) {
        self.queue.async {
            self.observerMap.removeValue(forKey: key)
        }
    }
    
}

extension Client: IMClientDelegate {
    
    func client(_ client: IMClient, event: IMClientEvent) {
        self.specificAssertion
        var text: String = ""
        switch event {
        case .sessionDidOpen:
            text = "Open Success"
        case .sessionDidResume:
            text = "In Resuming"
        case .sessionDidPause(error: let error):
            text = "Paused\n\(error)"
        case .sessionDidClose(error: let error):
            text = "Closed\n\(error)"
        }
        mainQueueExecuting {
            UIApplication.shared.keyWindow?.bringSubviewToFront(self.sessionStatusView)
            self.sessionStatusView.label.text = text
        }
    }
    
    func client(_ client: IMClient, conversation: IMConversation, event: IMConversationEvent) {
        self.specificAssertion
        for item in self.observerMap.values {
            item(client, conversation, event)
        }
    }
    
}
