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
    
    @IBOutlet var backArrowContainer: UIImageView!
    @IBOutlet var sendImageContainer: UIImageView!
    @IBOutlet var dotsImageContainer: UIImageView!
    
    @IBOutlet var tableView: UITableView!
    
    var messageVerticalBuffer:CGFloat = 15
    
    var allMessagesLoaded = false
    var loadMessageCallInFlight = false
    var currentStartToken: String! = nil
    var chatRoomId: String!
    var myAlias: Alias!
    var allActions: [AnyObject] = []
    
    var sendEnabled: Bool = false {
        didSet {
            if (sendEnabled) {
                sendImageContainer.image = UIImage(named: "SendDisabled")
            }
            else {
                sendImageContainer.image = UIImage(named: "SendDisabled")
            }
        }
    }
    
    override func viewDidLoad() {
        tableView.registerNib(UINib(nibName: "ChatCell", bundle: nil), forCellReuseIdentifier: "ChatCell")
        tableView.registerNib(UINib(nibName: "PresenceCell", bundle: nil), forCellReuseIdentifier: "PresenceCell")
        
        initStyle()
        
        Utilities.appDelegate().subscribeToPubNubChannel(chatRoomId, alias: myAlias)
        setupObervers()
        loadNextPageMessages()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "newMessage", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "newPresenceEvent", object: nil)
    }
    
    func initStyle() {
        topBar.backgroundColor = ColorConstants.solidGray
        chatBar.backgroundColor = ColorConstants.solidGray
        topBarDivider.backgroundColor = ColorConstants.dividerGray
        chatBarDivider.backgroundColor = ColorConstants.dividerGray
        
        backArrowContainer.image = UIImage(named: "BackArrow")
        dotsImageContainer.image = UIImage(named: "ThreeDots")
        sendEnabled = false
    }
    
    func setupObervers() {
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "deselectTextView"))
        chatBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "selectTextView"))
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserverForName("newMessage", object: nil, queue: nil) { (notification: NSNotification) -> Void in
            self.receiveMessage(notification.object as! Message)
        }
        NSNotificationCenter.defaultCenter().addObserverForName("newPresenceEvent", object: nil, queue: nil) { (notification: NSNotification) -> Void in
            self.receivePresenceEvent(notification.object as! Presence)
        }
    }
    
    @IBAction func closeChat() {
        delegate?.leaveChat(myAlias)
    }
    
    @IBAction func sendPress() {
        if (!sendEnabled) {
            return
        }
        
        let text = textView.text!
        textView.text = ""
        
        let message = Message.createMessage(text, alias: myAlias, timestamp: nil)
        sendMessage(message)
        addMessage(message)
    }
    
    @IBAction func dotsPress() {
        
    }
    
    @IBAction func textViewChange() {
        sendEnabled = (textView.text != "")
    }
    
    func loadNextPageMessages() {
        
        var params: [NSObject:AnyObject] = ["count":25, "aliasId": myAlias.objectId!, "subkey":EnvironmentConstants.pubNubSubscribeKey]
        if (currentStartToken != nil) {
            params["startTimeToken"] = currentStartToken
        }
        
        loadMessageCallInFlight = true
        PFCloud.callFunctionInBackground("replayEvents", withParameters: params) { (object: AnyObject?, error: NSError?) -> Void in
            
            var replayEvents = [AnyObject]()
            
            if let startToken = object?["startTimeToken"] as? String {
                self.currentStartToken = startToken
            }
            
            if let events = object?["events"] as? [[NSObject:AnyObject]] {
                
                if (events.count < 25) {
                    self.allMessagesLoaded = true
                }
                
                for eventDict in events {
                    
                    let objectType = eventDict["objectType"] as! String
                    let objectDict = eventDict["object"] as! [NSObject:AnyObject]
                    
                    if (objectType == "messageEvent") {
                        replayEvents.append(Message.createMessage(objectDict))
                    }
                    else if (objectType == "presenceEvent") {
                        replayEvents.append(Presence.createPresenceEvent(objectDict))
                    }
                }
                
                self.allActions = replayEvents + self.allActions
                self.tableView.reloadData()
                self.view.setNeedsDisplay()
                
                if (replayEvents.count == self.allActions.count) {
                    self.scrollToBottom(false)
                }
                else {
                    self.scrollToEventIndex(replayEvents.count, animated: false)
                }
            }
            
            self.loadMessageCallInFlight = false
        }
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
        Utilities.appDelegate().sendPubNubMessage(message, mobilePushPayload: nil, toChannel: message.alias.chatRoomId)
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
    
    func scrollToBottom(animated: Bool) {
        if (allActions.count == 0) {
            return;
        }
        
        let indexPath = NSIndexPath(forRow: allActions.count - 1, inSection:0)
        self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition:UITableViewScrollPosition.Bottom, animated:animated)
    }
    
    func scrollToEventIndex(index: Int, animated: Bool) {
        let indexPath = NSIndexPath(forRow: index, inSection:0)
        self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition:UITableViewScrollPosition.Top, animated:animated)
    }
    
    func addMessage(message: Message) {
        allActions.append(message)
        
        tableView.reloadData()
        view.setNeedsDisplay()
        scrollToBottom(true)
    }
    
    func addPresenceEvent(presenceEvent: Presence) {
        allActions.append(presenceEvent)
        
        tableView.reloadData()
        view.setNeedsDisplay()
        scrollToBottom(true)
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
        
        let event = allActions[indexPath.row]
        if let message = event as? Message {
            let cell = tableView.dequeueReusableCellWithIdentifier("ChatCell", forIndexPath: indexPath) as! ChatCell
            cell.setMessageText(message.body, alias: message.alias, isOutbound: isMyMessage(message), showAliasLabel: shouldShowAliasForMessageIndex(indexPath.row))
            return cell
        }
        else if let presenceEvent = event as? Presence {
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
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (allMessagesLoaded || loadMessageCallInFlight) {
            return
        }
        
        if (tableView.contentOffset.y <= 50) {
            loadNextPageMessages()
        }
    }
}
