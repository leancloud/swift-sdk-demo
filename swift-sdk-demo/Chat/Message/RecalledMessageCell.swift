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
    
    @IBOutlet weak var contentTextLabel: UILabel!
    
    func update(with message: IMRecalledMessage) {
        self.contentTextLabel.text = "\(message.fromClientID ?? "?") has recalled a message"
    }
    
}
