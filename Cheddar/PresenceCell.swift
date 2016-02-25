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
    
    func setAlias(alias: Alias, andAction action: String) {
        self.alias = alias
        self.action = action
        aliasLabel.text = alias.name + " " + getActionString(action)
    }
    
    func getActionString(action: String!) -> String! {
        if (action == "join") {
            return "Joined"
        }
        else if (action == "leave") {
            return "Left"
        }
        else {
            return nil
        }
    }
    
}