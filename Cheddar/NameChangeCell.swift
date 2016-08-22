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
    
    @IBOutlet var timestampLabel: UILabel!
    @IBOutlet var timestampLabelView: UIView!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    
    static var bottomBufferSize:CGFloat = 4
    
    override func willMoveToSuperview(newSuperview: UIView?) {
        backgroundView?.backgroundColor = ColorConstants.whiteColor
        timestampLabel.backgroundColor = ColorConstants.whiteColor
        bodyLabel.backgroundColor = ColorConstants.whiteColor
        nameLabel.backgroundColor = ColorConstants.whiteColor
    }
    
    func setEvent(nameChangeEvent: ChatEvent, showTimestamp: Bool, showBottomBuffer:Bool) {
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
            timestampLabelView.hidden = false;
        } else {
            timestampLabelView.hidden = true;
        }
        
        if (showBottomBuffer) {
            bottomConstraint.constant = NameChangeCell.bottomBufferSize
        }
        else {
            bottomConstraint.constant = 0
        }
    }
}
