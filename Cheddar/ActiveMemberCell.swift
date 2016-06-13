//
//  ActiveMemberCell.swift
//  Cheddar
//
//  Created by Lucas Haber on 5/15/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class ActiveMemberCell: UITableViewCell {
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var joinedAtLabel: UILabel!
    @IBOutlet var aliasIconContainer: UIView!
    
    var aliasIcon: AliasCircleView!
    
    func setAlias(alias: Alias, chatRoom: ChatRoom) {
        if (aliasIcon == nil) {
            var color: UIColor
            if (alias.objectId != chatRoom.myAlias.objectId) {
                color = ColorConstants.iconColors[Int(alias.colorId)]
            }
            else {
                color = ColorConstants.outboundChatBubble
            }
            
            aliasIcon = AliasCircleView.instanceFromNibWithAlias(alias, color: color, sizeFactor: 0.6)
            aliasIconContainer.addSubview(aliasIcon)
            aliasIcon.autoPinEdgesToSuperviewEdges()
            layoutIfNeeded()
        }
    }
}