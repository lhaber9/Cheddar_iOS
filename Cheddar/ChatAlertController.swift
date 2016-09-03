//
//  ChatAlertController.swift
//  Cheddar
//
//  Created by Lucas Haber on 4/13/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol ChatAlertDelegate: class {
    func hideNewMessageAlert()
    func showChatRoom(_ chatRoom: ChatRoom)
}

class ChatAlertController: UIViewController {
    
    weak var delegate: ChatAlertDelegate!
    
    @IBOutlet var alertView: UIView!
    @IBOutlet var aliasIconContainer: UIView!
    @IBOutlet var mainLabel: UILabel!
    @IBOutlet var subLabel: UILabel!
    var chatRoom: ChatRoom!
    var chatEvent: ChatEvent!
    
    var aliasIcon: AliasCircleView!
    
    override func viewDidLoad() {
        alertView.layer.shadowOffset = CGSize(width: -2, height: 0);
        alertView.layer.shadowRadius = 2;
        alertView.layer.shadowOpacity = 0.45;
        alertView.layer.shadowColor = UIColor.black.cgColor
        
        mainLabel.adjustsFontSizeToFitWidth = true
    }
    
    func refreshView() {
        var color: UIColor
        if (chatEvent.alias.objectId != chatRoom.myAlias.objectId) {
            color = ColorConstants.iconColors[Int(chatEvent.alias.colorId)]
        }
        else {
            color = ColorConstants.outboundChatBubble
        }
        
        aliasIcon = AliasCircleView.instanceFromNibWithAlias(chatEvent.alias, color: color, sizeFactor: 0.6)
        aliasIconContainer.addSubview(aliasIcon)
        aliasIcon.autoPinEdgesToSuperviewEdges()
        
        mainLabel.text = chatRoom.name
        subLabel.text = Utilities.formattedLastMessageText(chatEvent)
        
        view.layoutIfNeeded()
    }
    
    @IBAction func tapped() {
        delegate.hideNewMessageAlert()
        delegate.showChatRoom(chatRoom)
    }
}
