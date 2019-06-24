//
//  MediaMessageCell.swift
//  Chat
//
//  Created by zapcannon87 on 2019/5/14.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud

class MediaMessageCell: UITableViewCell {
    
    @IBOutlet weak var leftAvatarContainer: UIView!
    @IBOutlet weak var leftAvatarImageView: UIImageView!
    
    @IBOutlet weak var rightAvatarContainer: UIView!
    @IBOutlet weak var rightAvatarImageView: UIImageView!
    
    @IBOutlet weak var buttonContainer: UIView!
    @IBOutlet weak var messageFromLabel: UILabel!
    @IBOutlet weak var messagePlayButton: UIButton!
    @IBOutlet weak var messageInfoLabel: UILabel!
    @IBOutlet weak var messageDateLabel: UILabel!
    
    var url: URL?
    var handlerForURL: ((URL) -> Void)?
    
    func update(with message: IMCategorizedMessage) {
        self.buttonContainer.layer.cornerRadius = 4
        if message.ioType == .out {
            self.leftAvatarContainer.isHidden = true
            self.rightAvatarContainer.isHidden = false
            self.buttonContainer.backgroundColor = UIColor(red: 194.0 / 255.0, green: 224.0 / 255.0, blue: 198.0 / 255.0, alpha: 1.0)
            self.messageFromLabel.textAlignment = .right
            self.messageDateLabel.textAlignment = .left
        } else {
            self.leftAvatarContainer.isHidden = false
            self.rightAvatarContainer.isHidden = true
            self.buttonContainer.backgroundColor = UIColor.white
            self.messageFromLabel.textAlignment = .left
            self.messageDateLabel.textAlignment = .right
        }
        
        switch message {
        case let audioMessage as IMAudioMessage:
            self.url = audioMessage.url
            self.messagePlayButton.setTitle("Audio.\(audioMessage.format ?? "unknown")", for: .normal)
            self.messageInfoLabel.text = "Duration: \((audioMessage.duration ?? 0).rounded(.awayFromZero))s, Size: \(audioMessage.size ?? 0)bytes"
        case let videoMessage as IMVideoMessage:
            self.url = videoMessage.url
            self.messagePlayButton.setTitle("Video.\(videoMessage.format ?? "unknown")", for: .normal)
            self.messageInfoLabel.text = "Duration: \((videoMessage.duration ?? 0).rounded(.awayFromZero))s, Size: \(videoMessage.size ?? 0)bytes"
        case let fileMessage as IMFileMessage:
            self.url = fileMessage.url
            self.messagePlayButton.setTitle("File.\(fileMessage.format ?? "unknown")", for: .normal)
            self.messageInfoLabel.text = "Size: \(fileMessage.size ?? 0)bytes"
        default:
            fatalError()
        }
        
        self.messageFromLabel.text = message.fromClientID ?? "-"
        if let date = message.sentDate {
            self.messageDateLabel.text = "sent: \(dateFormatter.string(from: date))"
        } else {
            self.messageDateLabel.text = "-"
        }
    }
    
    @IBAction func buttonAction(_ sender: UIButton) {
        if let url = self.url {
            self.handlerForURL?(url)
        }
    }
    
}
