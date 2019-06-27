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
        
        let viewControllers: [UIViewController] = [
            UINavigationController(rootViewController: NormalConversationListViewController()),
            UINavigationController(rootViewController: ChatRoomListViewController()),
            UINavigationController(rootViewController: SettingsViewController())
        ]
        
        self.setViewControllers(
            viewControllers,
            animated: false
        )
        self.tabBar.items?[0].title = "Conversation"
        self.tabBar.items?[1].title = "ChatRoom"
        self.tabBar.items?[2].title = "Settings"
    }
    
}
