//
//  ImageMessageCell.swift
//  Chat
//
//  Created by zapcannon87 on 2019/5/13.
//  Copyright © 2019 LeanCloud. All rights reserved.
//

import Foundation
import UIKit
import LeanCloud
import AlamofireImage

class ImageMessageCell: UITableViewCell {
    
    @IBOutlet weak var leftAvatarContainer: UIView!
    @IBOutlet weak var leftAvatarImageView: UIImageView!
    
    @IBOutlet weak var rightAvatarContainer: UIView!
    @IBOutlet weak var rightAvatarImageView: UIImageView!
    
    @IBOutlet weak var messageFromLabel: UILabel!
    @IBOutlet weak var messageImageView: UIImageView!
    @IBOutlet weak var messageDateLabel: UILabel!
    
    func update(with message: IMImageMessage) {
        if message.ioType == .out {
            self.leftAvatarContainer.isHidden = true
            self.rightAvatarContainer.isHidden = false
            self.messageFromLabel.textAlignment = .right
            self.messageDateLabel.textAlignment = .left
        } else {
            self.leftAvatarContainer.isHidden = false
            self.rightAvatarContainer.isHidden = true
            self.messageFromLabel.textAlignment = .left
            self.messageDateLabel.textAlignment = .right
        }
        
        self.messageFromLabel.text = message.fromClientID ?? "-"
        
        let scale = Double(UIScreen.main.scale)
        let imageWidth: Double = (message.width ?? 300.0) / scale
        let imageHeight: Double = (message.height ?? 300.0) / scale
        let imageSize = CGSize(width: imageWidth, height: imageHeight)
        let placeholderImage = UIImage.whiteImage(size: imageSize)
        if let url = message.url {
            self.messageImageView.af_setImage(withURL: url, placeholderImage: placeholderImage)
        } else {
            self.messageImageView.image = placeholderImage
        }
        
        if let date = message.sentDate {
            self.messageDateLabel.text = "sent: \(dateFormatter.string(from: date))"
        } else {
            self.messageDateLabel.text = "-"
        }
    }
    
}
