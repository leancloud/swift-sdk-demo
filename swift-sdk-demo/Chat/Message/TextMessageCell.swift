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
    
    @IBOutlet weak var leftAvatarContainer: UIView!
    @IBOutlet weak var leftAvatarImageView: UIImageView!
    
    @IBOutlet weak var rightAvatarContainer: UIView!
    @IBOutlet weak var rightAvatarImageView: UIImageView!
    
    @IBOutlet weak var messageTextBackgroundView: UIView!
    @IBOutlet weak var messageFromLabel: UILabel!
    @IBOutlet weak var messageTextLabel: UILabel!
    @IBOutlet weak var messageDateLabel: UILabel!
    
    func update(with message: IMCategorizedMessage) {
        self.messageTextBackgroundView.layer.cornerRadius = 4
        if message.ioType == .out {
            self.leftAvatarContainer.isHidden = true
            self.rightAvatarContainer.isHidden = false
            self.messageTextBackgroundView.backgroundColor = UIColor(red: 194.0 / 255.0, green: 224.0 / 255.0, blue: 198.0 / 255.0, alpha: 1.0)
            self.messageFromLabel.textAlignment = .right
            self.messageTextLabel.textAlignment = .right
            self.messageDateLabel.textAlignment = .left
        } else {
            self.leftAvatarContainer.isHidden = false
            self.rightAvatarContainer.isHidden = true
            self.messageTextBackgroundView.backgroundColor = UIColor.white
            self.messageFromLabel.textAlignment = .left
            self.messageTextLabel.textAlignment = .left
            self.messageDateLabel.textAlignment = .right
        }
        self.messageFromLabel.text = message.fromClientID ?? "-"
        if let locationMessage = message as? IMLocationMessage {
            self.messageTextLabel.text = "Latitude: \(locationMessage.latitude ?? 0)\nLongitude: \(locationMessage.longitude ?? 0)"
        } else {
            self.messageTextLabel.text = message.text ?? "-"
        }
        if let date = message.sentDate {
            var dateText: String = "sent: \(dateFormatter.string(from: date))"
            if let patchDate = message.patchedDate {
                dateText += ", edit: \(dateFormatter.string(from: patchDate))"
            }
            self.messageDateLabel.text = dateText
        } else {
            self.messageDateLabel.text = "-"
        }
    }
    
}
