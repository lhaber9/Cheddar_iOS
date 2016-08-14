//
//  PresenceCell.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/25/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class PresenceCell: UITableViewCell {

    @IBOutlet var aliasLabel: UILabel!
    @IBOutlet var topConstraintTimestamp: NSLayoutConstraint!
    @IBOutlet var timestampLabel: UILabel!
    @IBOutlet var timestampLabelView: UIView!
    @IBOutlet var timestampLabelTopConstraint: NSLayoutConstraint!
    var alias: Alias!
    var body: String!
    
    func setAlias(presenceEvent: ChatEvent, showTimestamp:Bool, isFirstEvent:Bool) {
        if (presenceEvent.type != ChatEventType.Presence.rawValue) {
            return
        }
        
        self.alias = presenceEvent.alias
        aliasLabel.text = presenceEvent.body.uppercaseString
        aliasLabel.textColor = ColorConstants.presenceText
        
        if (showTimestamp) {
            timestampLabel.text = Utilities.formatDate(presenceEvent.createdAt, withTrailingHours: true)
            timestampLabel.textColor = ColorConstants.timestampText
            topConstraintTimestamp.priority = 950;
            timestampLabelView.hidden = false;
        } else {
            topConstraintTimestamp.priority = 200;
            timestampLabelView.hidden = true;
        }
        
        if (isFirstEvent) {
            timestampLabelTopConstraint.constant = ChatCell.bufferSize
        }
        else {
            timestampLabelTopConstraint.constant = 0
        }
    }
}