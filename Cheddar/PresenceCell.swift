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
    @IBOutlet var timestampLabel: UILabel!
    @IBOutlet var timestampLabelView: UIView!
    @IBOutlet var timestampLabelTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var activityIndicator:UIActivityIndicatorView!
    
    var alias: Alias!
    var body: String!
    
    func setAlias(presenceEvent: ChatEvent, showTimestamp:Bool, isFirstEvent:Bool, showActivityIndicator: Bool) {
        if (presenceEvent.type != ChatEventType.Presence.rawValue) {
            return
        }
        
        self.alias = presenceEvent.alias
        aliasLabel.text = presenceEvent.body.uppercaseString
        aliasLabel.textColor = ColorConstants.presenceText
        
        if (showTimestamp) {
            timestampLabel.text = Utilities.formatDate(presenceEvent.createdAt, withTrailingHours: true)
            timestampLabel.textColor = ColorConstants.timestampText
            timestampLabelView.hidden = false;
        } else {
            timestampLabelView.hidden = true;
        }
        
//        if (isFirstEvent) {
//            timestampLabelTopConstraint.constant = ChatCell.bufferSize
//        }
//        else {
//            timestampLabelTopConstraint.constant = 0
//        }
        
        if (showActivityIndicator) {
            activityIndicator.hidden = false
            activityIndicator.startAnimating()
        } else {
            activityIndicator.hidden = true
            activityIndicator.startAnimating()
        }
    }
}