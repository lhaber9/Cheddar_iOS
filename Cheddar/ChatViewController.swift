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
    func closeChat()
}

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    
    weak var delegate: ChatViewControllerDelegate?
    
    @IBOutlet var textView: UITextView!
    @IBOutlet var placeholderLabel: UILabel!
    @IBOutlet var topBar: UIView!
    @IBOutlet var topBarDivider: UIView!
    @IBOutlet var chatBarDivider: UIView!
    @IBOutlet var chatBar: UIView!
    
    @IBOutlet var chatBarBottomConstraint: NSLayoutConstraint!
    @IBOutlet var chatBarHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var sendButton: UIButton!
    
    @IBOutlet var tableView: UITableView!
    
    var messageVerticalBuffer:CGFloat = 15
    var chatBarHeightDefault:CGFloat = 50
    
    var allMessagesLoaded = false
    var loadMessageCallInFlight = false
    var leaveChatRoomCalInFlight = false
    var currentStartToken: String! = nil
    
    var previousTextRect = CGRectZero
    
    var chatRoomId: String!
    var myAlias: Alias!
    var allActions: [AnyObject] = []
    
    var numberInputTextLines = 1 {
        didSet {
            
            var offsetFromDefault:CGFloat = 0
            
            if (numberInputTextLines == 3){
                offsetFromDefault = textView.font!.lineHeight
            }
            else if (numberInputTextLines >= 4) {
                offsetFromDefault = textView.font!.lineHeight * 2
            }
            
            UIView.animateWithDuration(0.333) { () -> Void in
                self.chatBarHeightConstraint.constant = self.chatBarHeightDefault + offsetFromDefault
                self.view.layoutIfNeeded()
                if (self.numberInputTextLines <= 4) {
                    self.textView.scrollRangeToVisible(NSMakeRange(0, 1))
                }
                else {
                    self.textView.scrollRangeToVisible(self.textView.selectedRange)
                }
            }

        }
    }
    
    var lastNumberOfTextLines = 0
    
    var sendEnabled: Bool! {
        didSet {
            sendButton.enabled = sendEnabled
            placeholderLabel.hidden = sendEnabled
        }
    }
    
    override func viewDidLoad() {
        tableView.registerNib(UINib(nibName: "ChatCell", bundle: nil), forCellReuseIdentifier: "ChatCell")
        tableView.registerNib(UINib(nibName: "PresenceCell", bundle: nil), forCellReuseIdentifier: "PresenceCell")
        
        textView.delegate = self
        
        initStyle()
        subscribe()
        
        setupObervers()
        loadNextPageMessages()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "newMessage", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "newPresenceEvent", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "didSetDeviceToken", object: nil)
    }
    
    func initStyle() {
        topBar.backgroundColor = ColorConstants.headerBackground
        chatBar.backgroundColor = ColorConstants.sendBackground
        topBarDivider.backgroundColor = ColorConstants.headerBorder
        chatBarDivider.backgroundColor = ColorConstants.sendBorder

        sendEnabled = false
    }
    
    func subscribe() {
        Utilities.appDelegate().subscribeToPubNubChannel(chatRoomId)
        Utilities.appDelegate().subscribeToPubNubPushChannel(chatRoomId)
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
        NSNotificationCenter.defaultCenter().addObserverForName("didSetDeviceToken", object: nil, queue: nil) { (notification: NSNotification) -> Void in
            self.subscribe()
        }
    }
    
    @IBAction func backTap() {
        if (leaveChatRoomCalInFlight) {
            return
        }
        
        leaveChatRoomCalInFlight = true
        PFCloud.callFunctionInBackground("leaveChatRoom", withParameters: ["aliasId": myAlias.objectId!, "pubkey": EnvironmentConstants.pubNubPublishKey, "subkey": EnvironmentConstants.pubNubSubscribeKey]) { (object: AnyObject?, error: NSError?) -> Void in
            self.leaveChatRoomCalInFlight = false
            
            if (error != nil) {
                return
            }
            
            if let chatRoom = ChatRoom.fetchSingleRoom() {
                Utilities.appDelegate().managedObjectContext.deleteObject(chatRoom)
                Utilities.appDelegate().saveContext()
            }
            Utilities.appDelegate().unsubscribeFromPubNubChannel(self.myAlias.chatRoomId)
            Utilities.appDelegate().unsubscribeFromPubNubPushChannel(self.myAlias.chatRoomId)
            self.delegate?.closeChat()
        }
    }
    
    @IBAction func sendPress() {
        let text = textView.text!
        clearTextView()
        
        sendText(text)
    }
    
    @IBAction func dotsPress() {
        
    }
    
    func sendText(text: String) {
        let message = Message.createMessage(text, alias: myAlias, timestamp: nil, status:MessageStatus.Sent)
        sendMessage(message)
        addMessage(message)
    }
    
    func clearTextView() {
        textView.text = ""
        textViewDidChange(textView)
        numberInputTextLines = 0
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
    
    func findMyFirstSentMessageIndexMatchingText(text: String) -> Int! {
        if (allActions.count == 0) {
            return nil
        }
        
        var position = 0
        var retunIndex: Int! = nil
        
        while (retunIndex == nil && position < allActions.count) {
            
            if let thisMessage = allActions[position] as? Message {
                if (isMyMessage(thisMessage) && thisMessage.body == text && thisMessage.status == MessageStatus.Sent) {
                    retunIndex = position
                }
            }
            
            position++
        }
        return retunIndex
    }
    
    func deselectTextView() {
        textView.resignFirstResponder()
    }
    
    func selectTextView() {
        textView.becomeFirstResponder()
    }
    
    func sendMessage(message: Message) {
        Utilities.appDelegate().sendMessage(message)
    }
    
    func receiveMessage(message: Message) {
        if (isMyMessage(message)) {
            let messageIndex = findMyFirstSentMessageIndexMatchingText(message.body)
            (allActions[messageIndex] as! Message).status = MessageStatus.Success
            tableView.reloadData()
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
    
    func shouldShowAliasLabelForMessageIndex(messageIdx: Int) -> Bool {
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
    
    func shouldShowAliasIconForMessageIndex(messageIdx: Int) -> Bool {
        if let thisMessage = allActions[messageIdx] as? Message {
            let messageAfter = findFirstMessageAfterIndex(messageIdx)
            if (messageAfter != nil) {
                return messageAfter.alias.objectId != thisMessage.alias.objectId
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
            self.scrollToBottom(true)
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
            cell.setMessageText(message.body, alias: message.alias, isOutbound: isMyMessage(message), showAliasLabel: shouldShowAliasLabelForMessageIndex(indexPath.row), showAliasIcon: shouldShowAliasIconForMessageIndex(indexPath.row), status: message.status)
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
            
            var cellHeight = ChatCell.rowHeightForText(message.body, withAliasLabel: shouldShowAliasLabelForMessageIndex(indexPath.row)) + 4
            
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
    
    func textViewDidChange(textView: UITextView) {
        sendEnabled = (textView.text != "")
        
        let rows = Int(round((textView.contentSize.height - textView.textContainerInset.top - textView.textContainerInset.bottom) / textView.font!.lineHeight))
        
        if (numberInputTextLines != rows) {
            numberInputTextLines = rows
        }
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            sendPress()
            return false;
        }
        
        return true;
    }
}
