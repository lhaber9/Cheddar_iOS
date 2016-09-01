//
//  ChatListCell.swift
//  Cheddar
//
//  Created by Lucas Haber on 4/8/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class ChatListCell: UITableViewCell {

    @IBOutlet var aliasIconContainer: UIView!
    @IBOutlet var chatNameLabel: UILabel!
    @IBOutlet var lastMessageLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    var aliasIcon: AliasCircleView!
    var alias: Alias!
    
    override func awakeFromNib() {
        chatNameLabel.adjustsFontSizeToFitWidth = true
    }
    
    func setAlias(alias: Alias, chatRoom:ChatRoom) {
        var color: UIColor!
        if (alias.objectId != chatRoom.myAlias?.objectId) {
            color = ColorConstants.iconColors[Int(alias.colorId)]
        }
        else {
            color = ColorConstants.outboundChatBubble
        }
        
        if (aliasIcon == nil) {
            self.alias = alias
            aliasIcon = AliasCircleView.instanceFromNibWithAlias(alias, color: color, sizeFactor: 0.5)
            aliasIcon.setTextSize(22)
            aliasIconContainer.addSubview(aliasIcon)
            aliasIcon.autoPinEdgesToSuperviewEdges()
        }
        
        aliasIcon.setCellAlias(alias, color: color)
        self.alias = alias
        layoutIfNeeded()
    }
    
    func setMostRecentChatEvent(chatEvent: ChatEvent!, chatRoom:ChatRoom) {
        chatNameLabel.text = chatRoom.name
        
        if (chatEvent != nil) {
            lastMessageLabel.text = Utilities.formattedLastMessageText(chatEvent)
            setAlias(chatEvent.alias, chatRoom:chatRoom)
            timeLabel.hidden = false
            timeLabel.text = Utilities.formatDate(chatEvent.createdAt, withTrailingHours: false)
        }
        else {
            lastMessageLabel.text = "No Activity"
            setAlias(chatRoom.myAlias, chatRoom:chatRoom)
            timeLabel.hidden = true
        }
    }
    
    func showUnreadIndicator(show: Bool) {
        aliasIcon?.showUnreadIndicator(show)
        if (show) {
            chatNameLabel.font = UIFont(name: "Effra-Medium", size: 16)
        } else {
            chatNameLabel.font = UIFont(name: "Effra-Regular", size: 16)
        }
    }
}