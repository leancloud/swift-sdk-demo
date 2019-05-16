//
//  FileMessageCell.swift
//  Chat
//
//  Created by ZapCannon87 on 2019/5/16.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class FileMessageCell: UITableViewCell {
    
    @IBOutlet weak var messageAvatarImageView: UIImageView!
    @IBOutlet weak var messageFromLabel: UILabel!
    @IBOutlet weak var messageFileButton: UIButton!
    @IBOutlet weak var messageInfoLabel: UILabel!
    @IBOutlet weak var messageDateLabel: UILabel!
    
    var url: URL?
    var handlerForButton: ((URL) -> Void)?
    
    func update(with message: IMFileMessage) {
        self.url = message.url
        
        self.messageFromLabel.text = message.fromClientID ?? "-"
        self.messageInfoLabel.text = "Size: \(message.size ?? -1) bytes, Format: \(message.format ?? "-")"
        if let date = message.sentDate {
            self.messageDateLabel.text = dateFormatter.string(from: date)
        } else {
            self.messageDateLabel.text = "-"
        }
    }
    
    @IBAction func fileAction(_ sender: UIButton) {
        if let url = self.url {
            self.handlerForButton?(url)
        }
    }
    
}
