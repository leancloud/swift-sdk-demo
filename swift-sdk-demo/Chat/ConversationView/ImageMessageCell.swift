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
    
    @IBOutlet weak var messageAvatarImageView: UIImageView!
    @IBOutlet weak var messageFromLabel: UILabel!
    @IBOutlet weak var messageImageView: UIImageView!
    @IBOutlet weak var messageDateLabel: UILabel!
    
    func update(with message: IMImageMessage) {
        self.messageFromLabel.text = message.fromClientID ?? "-"
        
        let imageWidth: Double = message.width ?? 250
        let imageHeight: Double = message.height ?? 250
        let imageSize = CGSize(width: imageWidth, height: imageHeight)
        let placeholderImage = UIImage.whiteImage(size: imageSize)
        if let url = message.url {
            self.messageImageView.af_setImage(withURL: url, placeholderImage: placeholderImage)
        } else {
            self.messageImageView.image = placeholderImage
        }
        
        if let date = message.sentDate {
            self.messageDateLabel.text = dateFormatter.string(from: date)
        } else {
            self.messageDateLabel.text = "-"
        }
    }
    
}
