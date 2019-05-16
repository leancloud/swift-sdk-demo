//
//  ConversationListDetailsCell.swift
//  Chat
//
//  Created by zapcannon87 on 2019/5/7.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class ConversationListDetailsCell: UITableViewCell {
    
    static let height: CGFloat = 123.0
    
    @IBOutlet weak var convTypeLabel: UILabel!
    @IBOutlet weak var convIDLabel: UILabel!
    @IBOutlet weak var convUpdatedAtLabel: UILabel!
    @IBOutlet weak var convCreatedAtLabel: UILabel!
    @IBOutlet weak var convMembersCountLabel: UILabel!
    
    func update(with conversation: IMConversation) {
        var convType: String = "Normal"
        switch conversation {
        case is IMChatRoom:
            convType = "Transient"
        case is IMServiceConversation:
            convType = "System"
        case is IMTemporaryConversation:
            convType = "Temporary"
        default:
            if conversation.isUnique {
                convType += " Unique"
            }
        }
        self.convTypeLabel.text = "Conversation Type: \(convType)"
        self.convIDLabel.text = "Conversation ID: \(conversation.ID)"
        if let date: Date = conversation.updatedAt {
            self.convUpdatedAtLabel.text = "Updated At: \(dateFormatter.string(from: date))"
        } else {
            self.convUpdatedAtLabel.text = "Updated At: -"
        }
        if let date: Date = conversation.createdAt {
            self.convCreatedAtLabel.text = "Created At: \(dateFormatter.string(from: date))"
        } else {
            self.convCreatedAtLabel.text = "Created At: -"
        }
        if let members = conversation.members {
            self.convMembersCountLabel.text = "Members Count: \(members.count)"
        } else {
            self.convMembersCountLabel.text = "Members Count: -"
        }
    }
    
}
