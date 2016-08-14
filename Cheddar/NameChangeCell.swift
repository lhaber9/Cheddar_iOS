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
    
    @IBOutlet var topConstraintTimestamp: NSLayoutConstraint!
    @IBOutlet var timestampLabel: UILabel!
    @IBOutlet var timestampLabelView: UIView!
    
    func setEvent(nameChangeEvent: ChatEvent, showTimestamp: Bool) {
        if (nameChangeEvent.type != ChatEventType.NameChange.rawValue) {
            return
        }
        
        nameLabel.text = nameChangeEvent.roomName.uppercaseString
        nameLabel.textColor = ColorConstants.colorAccent
        
        bodyLabel.text = nameChangeEvent.body.substringToIndex(nameChangeEvent.body.endIndex.advancedBy(nameChangeEvent.roomName.characters.count * -1)).uppercaseString
        bodyLabel.textColor = ColorConstants.presenceText
        
        if (showTimestamp) {
            timestampLabel.text = Utilities.formatDate(nameChangeEvent.createdAt, withTrailingHours: true)
            timestampLabel.textColor = ColorConstants.timestampText
            topConstraintTimestamp.priority = 950;
            timestampLabelView.hidden = false;
        } else {
            timestampLabelView.hidden = true;
        }
    }
}
