//
//  RenameChatController.swift
//  Cheddar
//
//  Created by Lucas Haber on 5/13/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Parse

protocol RenameChatDelegate:class {
    func currentChatRoomName() -> String!
    func myAlias() -> Alias!
    func shouldCloseAll()
}

class RenameChatController: UIViewController {
    
    weak var delegate:RenameChatDelegate!
    
    @IBOutlet var chatRoomTitleText: UITextField!
    @IBOutlet var sendButton: CheddarButton!

    var callInFlight = false
    
    override func viewDidLoad() {
        chatRoomTitleText.text = delegate.currentChatRoomName()
        chatRoomTitleText.becomeFirstResponder()
        sendButton.setPrimaryButton()
    }
    
    @IBAction func sendTap() {
        if (callInFlight || chatRoomTitleText.text == "") {
            return
        }
        
        callInFlight = true
//        UIView.animateWithDuration(0.33) { 
//            self.sendLabel.alpha = 0
//            self.activityIndicator.alpha = 1
//            self.view.layoutIfNeeded()
//        }
        
        CheddarRequest.updateChatRoomName(delegate.myAlias().objectId,
                                          name: chatRoomTitleText.text!,
            successCallback: { (object) in
                
                self.callInFlight = false
                self.delegate.shouldCloseAll()
                
            }) { (error) in
                
                self.callInFlight = false
        }
    }
}