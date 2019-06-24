//
//  NormalConversationListCell.swift
//  Chat
//
//  Created by zapcannon87 on 2019/3/29.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class NormalConversationListCell: UITableViewCell {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var convNameLabel: UILabel!
    @IBOutlet weak var convLastMessageDateLabel: UILabel!
    @IBOutlet weak var convLastMessageContentLabel: UILabel!
    @IBOutlet weak var convUnreadCountLabel: UILabel!
    
    func update(with conversation: IMConversation) {
        self.convNameLabel.text = conversation.name ?? "-"
        
        let lastMessage = conversation.lastMessage
        if let date: Date = lastMessage?.sentDate {
            self.convLastMessageDateLabel.text = dateFormatter.string(from: date)
        } else {
            self.convLastMessageDateLabel.text = ""
        }
        
        var convLastMessageContentText: String?
        if let categorizedMessage = lastMessage as? IMCategorizedMessage {
            switch categorizedMessage {
            case is IMTextMessage:
                convLastMessageContentText = categorizedMessage.text
            case is IMImageMessage:
                convLastMessageContentText = categorizedMessage.text ?? "[Image]"
            case is IMAudioMessage:
                convLastMessageContentText = categorizedMessage.text ?? "[Audio]"
            case is IMVideoMessage:
                convLastMessageContentText = categorizedMessage.text ?? "[Video]"
            case is IMLocationMessage:
                convLastMessageContentText = categorizedMessage.text ?? "[Location]"
            case is IMFileMessage:
                convLastMessageContentText = categorizedMessage.text ?? "[File]"
            case is IMRecalledMessage:
                convLastMessageContentText = categorizedMessage.text ?? "[Recalled]"
            default:
                break
            }
        } else {
            convLastMessageContentText = lastMessage?.content?.string
        }
        self.convLastMessageContentLabel.text = convLastMessageContentText ?? "-"
        
        let count = conversation.unreadMessageCount
        self.convUnreadCountLabel.text = "\(count)"
        self.convUnreadCountLabel.isHidden = (count == 0) ? true : false
    }
    
}
