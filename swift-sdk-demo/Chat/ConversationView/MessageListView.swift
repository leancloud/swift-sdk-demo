//
//  MessageListView.swift
//  Chat
//
//  Created by zapcannon87 on 2019/3/31.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit

class MessageListView: UIView {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageInputView: UIView!
    @IBOutlet weak var messageInputViewAttachButton: UIButton!
    @IBOutlet weak var messageInputViewTextField: UITextField!
    @IBOutlet weak var messageInputViewSendButton: UIButton!
    @IBOutlet weak var messageInputViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var messageInputViewBottomConstraint: NSLayoutConstraint!
    
}
