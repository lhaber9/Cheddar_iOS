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
    
    func setAlias(alias: Alias, chatRoom:ChatRoom) {
        var color: UIColor!
        if (alias.objectId != chatRoom.myAlias.objectId) {
            color = ColorConstants.inboundIcons[Int(alias.colorId)]
        }
        else {
            color = ColorConstants.outboundChatBubble
        }
        
        if (aliasIcon == nil) {
            self.alias = alias
            aliasIcon = AliasCircleView.instanceFromNibWithAlias(alias, color: color, sizeFactor: 0.5)
            aliasIconContainer.addSubview(aliasIcon)
            aliasIcon.autoPinEdgesToSuperviewEdges()
        }
        
        if (self.alias.objectId != alias.objectId) {
            aliasIcon.setCellAlias(alias, color: color)
        }
        
        self.alias = alias
        layoutIfNeeded()
    }
    
    func setMostRecentChatEvent(chatEvent: ChatEvent!, chatRoom:ChatRoom) {
        if (chatEvent != nil) {
            var lastMessageText: String = ""
            if (chatEvent.type == ChatEventType.Message.rawValue) {
                lastMessageText = chatEvent.alias.name + ": "
            }
            
            lastMessageText = lastMessageText + chatEvent.body
            
            if (chatEvent.type == ChatEventType.NameChange.rawValue) {
                lastMessageText = lastMessageText.substringToIndex(lastMessageText.endIndex.advancedBy((chatEvent.roomName.characters.count + 4) * -1)) // +4 for _to_ text
            }
            
            lastMessageLabel.text = lastMessageText
            setAlias(chatEvent.alias, chatRoom:chatRoom)
            timeLabel.hidden = false
            
            let dateFor: NSDateFormatter = NSDateFormatter()
            dateFor.dateFormat = "h:mm a"
            
            timeLabel.text = dateFor.stringFromDate(chatEvent.createdAt)
        }
        else {
            lastMessageLabel.text = "No Activity"
            setAlias(chatRoom.myAlias, chatRoom:chatRoom)
            timeLabel.hidden = true
        }
    }
    
    func showUnreadIndicator(show: Bool) {
        aliasIcon?.showUnreadIndicator(show)
    }
}