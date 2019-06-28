//
//  TabBarController.swift
//  Chat
//
//  Created by zapcannon87 on 2019/3/27.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit

class TabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = .white
        
        let vc1 = UINavigationController(rootViewController: NormalConversationListViewController())
        vc1.tabBarItem.title = "Conversation"
        let vc2 = UINavigationController(rootViewController: ChatRoomListViewController())
        vc2.tabBarItem.title = "ChatRoom"
        let vc3 = UINavigationController(rootViewController: ServiceConversationListViewController())
        vc3.tabBarItem.title = "Service"
        let vc4 = UINavigationController(rootViewController: TemporaryConversationListViewController())
        vc4.tabBarItem.title = "Temporary"
        let vc5 = UINavigationController(rootViewController: SettingsViewController())
        vc5.tabBarItem.title = "Settings"
        
        self.setViewControllers([vc1, vc2, vc3, vc4, vc5], animated: false)
    }
    
}
