//
//  ChatAlertController.swift
//  Cheddar
//
//  Created by Lucas Haber on 4/13/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol ChatAlertDelegate: class {
    func showChatRoom(chatRoom: ChatRoom)
}

class ChatAlertController: UIViewController {
    
    weak var delegate: ChatAlertDelegate!
    
    @IBOutlet var label: UILabel!
    var chatRoom: ChatRoom!
    
    @IBAction func tapped() {
        delegate.showChatRoom(chatRoom)
    }
}