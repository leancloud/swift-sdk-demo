//
//  VideoMessageCell.swift
//  Chat
//
//  Created by zapcannon87 on 2019/5/16.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class VideoMessageCell: UITableViewCell {
    
    @IBOutlet weak var messageAvatarImageView: UIImageView!
    @IBOutlet weak var messageFromLabel: UILabel!
    @IBOutlet weak var messagePlayButton: UIButton!
    @IBOutlet weak var messageInfoLabel: UILabel!
    @IBOutlet weak var messageDateLabel: UILabel!
    
    var url: URL?
    var handlerForPlayer: ((URL) -> Void)?
    
    func update(with message: IMVideoMessage) {
        self.url = message.url
        
        self.messageFromLabel.text = message.fromClientID ?? "-"
        self.messageInfoLabel.text = "Duration: \(message.duration ?? -1)s, Size: \(message.size ?? -1) bytes, Format: \(message.format ?? "-")"
        if let date = message.sentDate {
            self.messageDateLabel.text = dateFormatter.string(from: date)
        } else {
            self.messageDateLabel.text = "-"
        }
    }
    
    @IBAction func videoPlayingAction(_ sender: UIButton) {
        if let url = self.url {
            self.handlerForPlayer?(url)
        }
    }
    
}
