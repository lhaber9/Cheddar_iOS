//
//  ChatViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/6/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol ChatViewControllerDelegate: class {
    func closeChat()
}

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    weak var delegate: ChatViewControllerDelegate?
    
    @IBOutlet var textView: UITextField!
    @IBOutlet var chatBar: UIView!
    @IBOutlet var chatBarBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var tableView: UITableView!
    
    var messages: [Message] = []
    var channelId: String!
    var alias: Alias!
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "deselectTextView"))
        
        chatBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "selectTextView"))
        
        tableView.registerNib(UINib(nibName: "ChatCell", bundle: nil), forCellReuseIdentifier: "ChatCell")
        
        (UIApplication.sharedApplication().delegate as! AppDelegate).subscripeToPubNubChannel(channelId)
        
        NSNotificationCenter.defaultCenter().addObserverForName("newMessage", object: nil, queue: nil) { (notification: NSNotification) -> Void in
           self.receiveMessage(notification.object as! Message)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    @IBAction func closeChat() {
        delegate?.closeChat()
    }
    
    @IBAction func sendPress() {
        if (textView.text == "") {
            return
        }
        
        let text = textView.text!
        textView.text = ""
        
        let message = Message.createMessage(text, alias: alias, chatRoomId: channelId)
        sendMessage(message)
    }
    
    func deselectTextView() {
        textView.resignFirstResponder()
    }
    
    func selectTextView() {
        textView.becomeFirstResponder()
    }
    
    func sendMessage(message: Message) {
        (UIApplication.sharedApplication().delegate as! AppDelegate).sendPubNubMessage(message, mobilePushPayload: nil, toChannel: message.chatRoomId)
    }
    
    func receiveMessage(message: Message) {
        messages.append(message)
        
        tableView.reloadData()
        view.setNeedsDisplay()
    }
    
    func shouldShowAliasForMessageIndex(messageIdx: Int) -> Bool {
        
        if (messageIdx == 0) {
            return true;
        }
        else if (messageIdx < messages.count) {
            
            let thisMessage = messages[messageIdx]
            let lastMessage = messages[messageIdx - 1]
            
            return thisMessage.alias.objectId != lastMessage.alias.objectId
        }
        else {
            return false
        }
        
    }
    
    // Keyboard Delegate Methods
    
    func keyboardWillShow(notification: NSNotification) {
        
        let keyboardHeight: CGFloat = (notification.userInfo![UIKeyboardFrameEndUserInfoKey]?.CGRectValue.height)!
        
        UIView.animateWithDuration(0.333) { () -> Void in
            self.chatBarBottomConstraint.constant = keyboardHeight
            self.view.layoutIfNeeded()
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        UIView.animateWithDuration(0.333) { () -> Void in
            self.chatBarBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    // TableView Delegate Methods
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ChatCell", forIndexPath: indexPath) as! ChatCell
        
        let message = messages[indexPath.row]
        
        cell.setMessageText(message.body)
        cell.isOutbound = (message.alias.objectId == self.alias.objectId)
        cell.showAliasLabel = shouldShowAliasForMessageIndex(indexPath.row)
        cell.alias = message.alias
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return ChatCell.rowHeightForText(messages[indexPath.row].body, withAliasLabel: shouldShowAliasForMessageIndex(indexPath.row)) + 8
    }

}
