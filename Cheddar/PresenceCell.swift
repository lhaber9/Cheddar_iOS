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
    var alias: Alias!
    var action: String!
    
    func setAlias(alias: Alias, andAction action: String, isMine:Bool) {
        self.alias = alias
        self.action = action
        var text = alias.name.uppercaseString + " HAS " + getActionString(action)
        
        if (isMine && action == "join") {
            let dayTimePeriodFormatter = NSDateFormatter()
            dayTimePeriodFormatter.dateFormat = "dd/MM"
            
            let dateString = dayTimePeriodFormatter.stringFromDate(alias.joinedAt)
            
            text += " " + dateString
        }
        
        aliasLabel.text = text
        aliasLabel.textColor = ColorConstants.presenceText
    }
    
    func getActionString(action: String!) -> String! {
        if (action == "join") {
            return "JOINED"
        }
        else if (action == "leave") {
            return "LEFT"
        }
        else {
            return nil
        }
    }
    
}