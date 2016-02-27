//
//  ChatViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/6/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Parse

protocol ChatViewControllerDelegate: class {
    func leaveChat(alias:Alias)
}

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    weak var delegate: ChatViewControllerDelegate?
    
    @IBOutlet var textView: UITextField!
    @IBOutlet var topBar: UIView!
    @IBOutlet var topBarDivider: UIView!
    @IBOutlet var chatBarDivider: UIView!
    @IBOutlet var chatBar: UIView!
    @IBOutlet var chatBarBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet var tableView: UITableView!
    
    var messageVerticalBuffer:CGFloat = 15
    
    var chatRoomId: String!
    var myAlias: Alias!
//    var messages: [Message] = []
    var allActions: [AnyObject] = []
    
    override func viewDidLoad() {
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "deselectTextView"))
        chatBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "selectTextView"))
        
        tableView.registerNib(UINib(nibName: "ChatCell", bundle: nil), forCellReuseIdentifier: "ChatCell")
        tableView.registerNib(UINib(nibName: "PresenceCell", bundle: nil), forCellReuseIdentifier: "PresenceCell")
        
        topBar.backgroundColor = ColorConstants.solidGray
        chatBar.backgroundColor = ColorConstants.solidGray
        
        topBarDivider.backgroundColor = ColorConstants.dividerGray
        chatBarDivider.backgroundColor = ColorConstants.dividerGray
        
        (UIApplication.sharedApplication().delegate as! AppDelegate).subscribeToPubNubChannel(chatRoomId, alias: myAlias)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserverForName("newMessage", object: nil, queue: nil) { (notification: NSNotification) -> Void in
           self.receiveMessage(notification.object as! Message)
        }
        NSNotificationCenter.defaultCenter().addObserverForName("newPresenceEvent", object: nil, queue: nil) { (notification: NSNotification) -> Void in
            self.receivePresenceEvent(notification.object as! Presence)
        }
        
        PFCloud.callFunctionInBackground("replayForAlias", withParameters: ["count":25, "aliasId": myAlias.objectId!, "subkey":EnvironmentConstants.pubNubSubscribeKey]) { (object: AnyObject?, error: NSError?) -> Void in
            
            var events = [AnyObject]()
            
            if let messageEvents = object!["messageEvents"] as? [[NSObject:AnyObject]],
                   presenceEvents = object!["presenceEvents"] as? [[NSObject:AnyObject]] {
                    
                var messageIdx = 0
                var presenceIdx = 0
                    
                while (messageIdx < messageEvents.count || presenceIdx < presenceEvents.count) {
                    
                    if (messageIdx == messageEvents.count) {
                        let timestamp = presenceEvents[presenceIdx]["timestamp"] as! Int
                        let action = presenceEvents[presenceIdx]["data"]!["action"] as! String
                        let aliasDict = presenceEvents[presenceIdx]["data"]!["alias"] as! [NSObject:AnyObject]
                        
                        events.append(Presence.createPresenceEvent(timestamp, action: action, aliasDict: aliasDict))
                        presenceIdx++
                    }
                    else if (presenceIdx == presenceEvents.count) {
                        events.append(Message.createMessage(messageEvents[messageIdx]))
                        messageIdx++
                    }
                    else {
                        
                        if ((messageEvents[messageIdx]["timestamp"] as! Int) < (presenceEvents[presenceIdx]["timestamp"] as! Int)) {
                            events.append(Message.createMessage(messageEvents[messageIdx]))
                            messageIdx++
                        }
                        else {
                            let timestamp = presenceEvents[presenceIdx]["timestamp"] as! Int
                            let action = presenceEvents[presenceIdx]["data"]!["action"] as! String
                            let aliasDict = presenceEvents[presenceIdx]["data"]!["alias"] as! [NSObject:AnyObject]
                            
                            events.append(Presence.createPresenceEvent(timestamp, action: action, aliasDict: aliasDict))
                            presenceIdx++
                        }
                    }
                }
                
                self.allActions = events
                self.tableView.reloadData()
                self.view.setNeedsDisplay()
            }
            
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "newMessage", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "newPresenceEvent", object: nil)
    }
    
    @IBAction func closeChat() {
        delegate?.leaveChat(myAlias)
    }
    
    @IBAction func sendPress() {
        if (textView.text == "") {
            return
        }
        
        let text = textView.text!
        textView.text = ""
        
        let message = Message.createMessage(text, alias: myAlias, timestamp: nil)
        sendMessage(message)
        addMessage(message)
    }
    
    func isMyMessage(message: Message) -> Bool {
        return (message.alias.objectId == myAlias.objectId)
    }
    
    func isMyPresenceEvent(presenceEvent: Presence) -> Bool {
        return (presenceEvent.alias.objectId == myAlias.objectId)
    }
    
    func findFirstMessageBeforeIndex(index: Int) -> Message! {
        var position = index - 1
        if (position < 0) {
            return nil
        }
        
        var message = allActions[position]
        while (!message.isKindOfClass(Message)) {
            position--
            if (position < 0) { return nil }
            message = allActions[position]
        }
        return message as! Message
    }
    
    func findFirstMessageAfterIndex(index: Int) -> Message! {
        var position = index + 1
        if (position >= allActions.count) {
            return nil
        }
        
        var message = allActions[position]
        while (!message.isKindOfClass(Message)) {
            position++
            if (position >= allActions.count) { return nil }
            message = allActions[position]
        }
        return message as! Message
    }

    
    func deselectTextView() {
        textView.resignFirstResponder()
    }
    
    func selectTextView() {
        textView.becomeFirstResponder()
    }
    
    func sendMessage(message: Message) {
        (UIApplication.sharedApplication().delegate as! AppDelegate).sendPubNubMessage(message, mobilePushPayload: nil, toChannel: message.alias.chatRoomId)
    }
    
    func receiveMessage(message: Message) {
        if (isMyMessage(message)) {
            return;
        }
        
        addMessage(message)
    }
    
    func receivePresenceEvent(presenceEvent: Presence) {
//        if (isMyPresenceEvent(presenceEvent)) {
//            return;
//        }
        
        addPresenceEvent(presenceEvent)
    }
    
    func addMessage(message: Message) {
        allActions.append(message)
        
        tableView.reloadData()
        view.setNeedsDisplay()
    }
    
    func addPresenceEvent(presenceEvent: Presence) {
        allActions.append(presenceEvent)
        
        tableView.reloadData()
        view.setNeedsDisplay()
    }
    
    func shouldShowAliasForMessageIndex(messageIdx: Int) -> Bool {
        if let thisMessage = allActions[messageIdx] as? Message {
            let messageBefore = findFirstMessageBeforeIndex(messageIdx)
            if (messageBefore != nil) {
                return messageBefore.alias.objectId != thisMessage.alias.objectId
            }
            else {
                return true
            }
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
        return allActions.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let action = allActions[indexPath.row]
        if let message = action as? Message {
            let cell = tableView.dequeueReusableCellWithIdentifier("ChatCell", forIndexPath: indexPath) as! ChatCell
            cell.setMessageText(message.body)
            cell.isOutbound = isMyMessage(message)
            cell.showAliasLabel = shouldShowAliasForMessageIndex(indexPath.row)
            cell.alias = message.alias
            return cell
        }
        else if let presenceEvent = action as? Presence {
            let cell = tableView.dequeueReusableCellWithIdentifier("PresenceCell", forIndexPath: indexPath) as! PresenceCell
            cell.setAlias(presenceEvent.alias, andAction: presenceEvent.action)
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let action = allActions[indexPath.row]
        if let message = action as? Message {
            
            var cellHeight = ChatCell.rowHeightForText(message.body, withAliasLabel: shouldShowAliasForMessageIndex(indexPath.row)) + 4
            
            let nextMessage = findFirstMessageAfterIndex(indexPath.row)
            if (nextMessage?.alias.objectId != message.alias.objectId) {
                cellHeight += messageVerticalBuffer
            }
            
            return cellHeight
        }
        else if let _ = action as? Presence {
            return 33
        }
        return 0
    }

}
