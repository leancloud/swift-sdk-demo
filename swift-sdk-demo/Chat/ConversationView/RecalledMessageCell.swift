//
//  RecalledMessageCell.swift
//  Chat
//
//  Created by ZapCannon87 on 2019/5/17.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class RecalledMessageCell: UITableViewCell {
    
    @IBOutlet weak var messageAvatarImageView: UIImageView!
    @IBOutlet weak var messageFromLabel: UILabel!
    @IBOutlet weak var messageTextLabel: UILabel!
    @IBOutlet weak var messageDateLabel: UILabel!
    
    func update(with message: IMRecalledMessage) {
        self.messageFromLabel.text = message.fromClientID ?? "-"
        self.messageTextLabel.text = "Recalled Message"
        self.messageTextLabel.textColor = .red
        if let date = message.sentDate {
            self.messageDateLabel.text = dateFormatter.string(from: date)
        } else {
            self.messageDateLabel.text = "-"
        }
    }
    
}
