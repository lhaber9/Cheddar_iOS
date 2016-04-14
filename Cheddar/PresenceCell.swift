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
    var body: String!
    
    func setAlias(alias: Alias, andAction body: String, isMine:Bool) {
        self.alias = alias
        self.body = body
        
//        if (isMine && action == "join") {
//            let dayTimePeriodFormatter = NSDateFormatter()
//            dayTimePeriodFormatter.dateFormat = "LLL dd"
//            
//            let dateString = dayTimePeriodFormatter.stringFromDate(alias.joinedAt).uppercaseString
//            
//            text += " on " + dateString
//        }
        
        aliasLabel.text = body
        aliasLabel.textColor = ColorConstants.presenceText
    }
}