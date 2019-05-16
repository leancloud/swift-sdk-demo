//
//  LocationMessageCell.swift
//  Chat
//
//  Created by ZapCannon87 on 2019/5/16.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class LocationMessageCell: UITableViewCell {
    
    @IBOutlet weak var messageAvatarImageView: UIImageView!
    @IBOutlet weak var messageFromLabel: UILabel!
    @IBOutlet weak var messageLocationInfoLabel: UILabel!
    @IBOutlet weak var messageDateLabel: UILabel!
    
    func update(with message: IMLocationMessage) {
        self.messageFromLabel.text = message.fromClientID ?? "-"
        if let latitude = message.latitude, let longitude = message.longitude {
            self.messageLocationInfoLabel.text = "Latitude: \(latitude)\nlongitude: \(longitude)"
        } else {
            self.messageLocationInfoLabel.text = "Latitude: -\nlongitude: -"
        }
        if let date = message.sentDate {
            self.messageDateLabel.text = dateFormatter.string(from: date)
        } else {
            self.messageDateLabel.text = "-"
        }
    }
    
}
