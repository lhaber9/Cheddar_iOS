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

class RenameChatController: UIViewController, UITextFieldDelegate {
    
    weak var delegate:RenameChatDelegate!
    
    @IBOutlet var chatRoomTitleText: UITextField!
    @IBOutlet var sendButton: CheddarButton!
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var errorLabel: UILabel!
    @IBOutlet var charCountLabel: UILabel!
    
    var errorLabelTimer: NSTimer!
    var roomNameCharacterLimit = 30
    
    override func viewDidLoad() {
        chatRoomTitleText.text = delegate.currentChatRoomName()
        chatRoomTitleText.becomeFirstResponder()
        chatRoomTitleText.delegate = self
        sendButton.setPrimaryButton()
        errorLabel.textColor = ColorConstants.colorAccent
        titleLabel.textColor = ColorConstants.colorAccent
        charCountLabel.textColor = ColorConstants.textSecondary
        charCountLabel.text = " of " + String(roomNameCharacterLimit)
        
        chatRoomTitleText.addTarget(
            self,
            action: #selector(RenameChatController.textFieldDidChange),
            forControlEvents: UIControlEvents.EditingChanged
        )
        
        textFieldDidChange()
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
    
    func setText(text: String) {
        titleLabel.text = text
        textFieldDidChange()
    }
    
    func textFieldDidChange() {
        charCountLabel.text = String((chatRoomTitleText.text?.characters.count)! as Int) + " of " + String(roomNameCharacterLimit)
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        
        let oldLength = textField.text?.characters.count
        let replacementLength = string.characters.count
        let rangeLength = range.length
        
        let newLength = oldLength! - rangeLength + replacementLength;
        
        if (newLength <= roomNameCharacterLimit) {
            return true
        }
        
        displayError("must be less than 30 characters")
        return false
    }
}