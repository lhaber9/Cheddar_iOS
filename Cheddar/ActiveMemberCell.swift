//
//  ActiveMemberCell.swift
//  Cheddar
//
//  Created by Lucas Haber on 5/15/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol ActiveMembersCellDelegate:class {
    func reportAlias(alias:Alias)
}

class ActiveMemberCell: UITableViewCell {
    
    weak var delegate:ActiveMembersCellDelegate!
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var joinedAtLabel: UILabel!
    @IBOutlet var aliasIconContainer: UIView!
    
    var alias: Alias!
    var aliasIcon: AliasCircleView!
    
    func setAlias(alias: Alias, chatRoom: ChatRoom) {
        self.alias = alias
        if (aliasIcon == nil) {
            var color: UIColor
            if (alias.objectId != chatRoom.myAlias.objectId) {
                color = ColorConstants.iconColors[Int(alias.colorId)]
            }
            else {
                color = ColorConstants.outboundChatBubble
            }
            
            aliasIcon = AliasCircleView.instanceFromNibWithAlias(alias, color: color, sizeFactor: 0.6)
            aliasIcon.setTextSize(18)
            aliasIconContainer.addSubview(aliasIcon)
            aliasIcon.autoPinEdgesToSuperviewEdges()
        }
        
        nameLabel.text = alias.name
        joinedAtLabel.text = "Joined on " + Utilities.formatDate(alias.joinedAt, withTrailingHours: true)
        
        layoutIfNeeded()
    }
    
    @IBAction func reportAlias() {
        delegate.reportAlias(alias)
    }
}