//
//  TextMessageCell.swift
//  Chat
//
//  Created by zapcannon87 on 2019/5/8.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class TextMessageCell: UITableViewCell {
    
    @IBOutlet weak var messageAvatarImageView: UIImageView!
    @IBOutlet weak var messageFromLabel: UILabel!
    @IBOutlet weak var messageTextLabel: UILabel!
    @IBOutlet weak var messageDateLabel: UILabel!
    
    func update(with message: IMTextMessage) {
        self.messageFromLabel.text = message.fromClientID ?? "-"
        self.messageTextLabel.text = message.text ?? "-"
        if let date = message.sentDate {
            self.messageDateLabel.text = dateFormatter.string(from: date)
        } else {
            self.messageDateLabel.text = "-"
        }
    }
    
}
