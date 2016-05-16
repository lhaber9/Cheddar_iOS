//
//  NameChangeCell.swift
//  Cheddar
//
//  Created by Lucas Haber on 5/16/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class NameChangeCell: UITableViewCell {
    
    @IBOutlet var bodyLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    
    func setEvent(chatEvent: ChatEvent) {
        if (chatEvent.type != ChatEventType.NameChange.rawValue) {
            return
        }
        
        nameLabel.text = chatEvent.roomName.uppercaseString
        nameLabel.textColor = ColorConstants.colorAccent
        
        bodyLabel.text = chatEvent.body.substringToIndex(chatEvent.body.endIndex.advancedBy(chatEvent.roomName.characters.count * -1)).uppercaseString
        bodyLabel.textColor = ColorConstants.presenceText
    }
}
