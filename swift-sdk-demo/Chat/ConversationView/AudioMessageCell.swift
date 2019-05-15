//
//  AudioMessageCell.swift
//  Chat
//
//  Created by zapcannon87 on 2019/5/14.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class AudioMessageCell: UITableViewCell {
    
    @IBOutlet weak var messageAvatarImageView: UIImageView!
    @IBOutlet weak var messageFromLabel: UILabel!
    @IBOutlet weak var messagePlayButton: UIButton!
    @IBOutlet weak var messageInfoLabel: UILabel!
    @IBOutlet weak var messageDateLabel: UILabel!
    
    var url: URL?
    var handlerForPlayer: ((URL) -> Void)?
    
    func update(with message: IMAudioMessage) {
        self.url = message.url
        
        self.messageFromLabel.text = message.fromClientID ?? "-"
        self.messageInfoLabel.text = "Duration: \(message.duration ?? -1)s, Size: \(message.size ?? -1) bytes, Format: \(message.format ?? "-")"
        if let date = message.sentDate {
            self.messageDateLabel.text = dateFormatter.string(from: date)
        } else {
            self.messageDateLabel.text = ""
        }
    }
    
    @IBAction func audioPlayingAction(_ sender: UIButton) {
        if let url = self.url {
            self.handlerForPlayer?(url)
        }
    }
    
}
