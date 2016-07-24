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
    
    override func viewDidLoad() {
        chatRoomTitleText.text = delegate.currentChatRoomName()
        chatRoomTitleText.becomeFirstResponder()
        sendButton.setPrimaryButton()
        errorLabel.textColor = ColorConstants.colorAccent
        titleLabel.textColor = ColorConstants.colorAccent
    }
    
    @IBAction func sendTap() {
        if (chatRoomTitleText.text == "") {
            return
        }
        
        self.sendButton.displaySpinner()
        
        CheddarRequest.updateChatRoomName(delegate.myAlias().objectId,
                                          name: chatRoomTitleText.text!,
            successCallback: { (object) in
                
                self.delegate.shouldCloseAll()
                self.sendButton.removeSpinner()
                
            }) { (error) in
                
                self.displayError()
                self.sendButton.removeSpinner()
        }
    }
    
    func displayError() {
        UIView.animateWithDuration(0.333) {
            self.errorLabel.alpha = 1
            self.view.layoutIfNeeded()
        }
        
        NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(ChangeSchoolViewController.hideError), userInfo: nil, repeats: false)
    }
    
    func hideError() {
        UIView.animateWithDuration(0.333) {
            self.errorLabel.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
}