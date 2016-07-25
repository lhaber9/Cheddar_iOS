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
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var errorLabel: UILabel!
    
    var errorLabelTimer: NSTimer!
    
    override func viewDidLoad() {
        chatRoomTitleText.text = delegate.currentChatRoomName()
        chatRoomTitleText.becomeFirstResponder()
        sendButton.setPrimaryButton()
        errorLabel.textColor = ColorConstants.colorAccent
        titleLabel.textColor = ColorConstants.colorAccent
    }
    
    @IBAction func sendTap() {
        let newTitle = chatRoomTitleText.text!
        if (newTitle.isEmpty) {
            displayError("Name cannot be blank")
            return
        } else if (delegate.currentChatRoomName() == newTitle) {
            displayError("Name cannot be the same")
            return
        }
        
        self.sendButton.displaySpinner()
        
        CheddarRequest.updateChatRoomName(delegate.myAlias().objectId,
                                          name: chatRoomTitleText.text!,
            successCallback: { (object) in
                
                self.delegate.shouldCloseAll()
                self.sendButton.removeSpinner()
                
            }) { (error) in
                
                self.displayError("Error changing chat room name")
                self.sendButton.removeSpinner()
        }
    }
    
    func displayError(text: String) {
        errorLabel.text = text
        UIView.animateWithDuration(0.333) {
            self.errorLabel.alpha = 1
            self.view.layoutIfNeeded()
        }
        
        if (errorLabelTimer != nil) {
            errorLabelTimer.invalidate()
            errorLabelTimer = nil
        }
        
        errorLabelTimer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(RenameChatController.hideError), userInfo: nil, repeats: false)
    }
    
    func hideError() {
        UIView.animateWithDuration(0.333) {
            self.errorLabel.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
}