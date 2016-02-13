//
//  ChatViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/6/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var textView: UITextField!
    @IBOutlet var chatBar: UIView!
    @IBOutlet var chatBarBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var tableView: UITableView!
    
    var messages: [Message] = []
    var channelName: String = "test"
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "deselectTextView"))
        
        tableView.registerNib(UINib(nibName: "ChatCell", bundle: nil), forCellReuseIdentifier: "ChatCell")
        
        NSNotificationCenter.defaultCenter().addObserverForName("newMessage", object: nil, queue: nil) { (notification: NSNotification) -> Void in
            
           self.receiveMessage(notification.object as! Message)
        }
    }
    
    
    @IBAction func sendPress() {
        let text = textView.text!
        textView.text = ""
        
        let message = Message.createMessage(text, userId: User.theUser.userId, channel: channelName)
        
        sendMessage(message)
    }
    
    func receiveMessage(message: Message) {
        messages.append(message)
        
        tableView.reloadData()
        view.setNeedsDisplay()
    }
    
    func sendMessage(message: Message) {
        (UIApplication.sharedApplication().delegate as! AppDelegate).sendPubNubMessage(message, mobilePushPayload: nil, toChannel: message.channel)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
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
    
    func deselectTextView() {
        textView.resignFirstResponder()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ChatCell", forIndexPath: indexPath) as! ChatCell
        
        let message = messages[indexPath.row]
        
        cell.setMessageText(message.messageText)
        cell.isOutbound = (message.fromUserId == User.theUser.userId)
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return ChatCell.rowHeightForText(messages[indexPath.row].messageText)
    }

}
