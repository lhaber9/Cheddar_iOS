//
//  ChatViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/6/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Parse
import Crashlytics

protocol ChatViewControllerDelegate: class {
    func closeChat()
}

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, UIPopoverPresentationControllerDelegate, OptionsMenuControllerDelegate, ChatRoomControllerDelegate, FeedbackViewDelegate {
    
    weak var delegate: ChatViewControllerDelegate?
    
    @IBOutlet var loadingView: UIView!
    
    @IBOutlet var textView: UITextView!
    @IBOutlet var placeholderLabel: UILabel!
    @IBOutlet var numActiveLabel: UILabel!
    @IBOutlet var topBar: UIView!
    @IBOutlet var topBarDivider: UIView!
    @IBOutlet var chatBarDivider: UIView!
    @IBOutlet var chatBar: UIView!
    
    @IBOutlet var backButton: UIButton!
    @IBOutlet var dotsButton: UIButton!
    
    @IBOutlet var chatBarBottomConstraint: NSLayoutConstraint!
    @IBOutlet var chatBarHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var sendButton: UIButton!
    
    @IBOutlet var tableView: UITableView!
    
    var messageVerticalBuffer:CGFloat = 15
    var chatBarHeightDefault:CGFloat = 65
    var previousTextRect = CGRectZero
    
    var chatRoomController:ChatRoomController!
    
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
        chatRoomController.delegate = self
        chatRoomController.reloadActiveAlaises()
        
        initStyle()
        subscribe()
        
        setupObervers()
        
        PFCloud.callFunctionInBackground("findAlias", withParameters: ["aliasId": chatRoomController.myAlias.objectId]) { (object: AnyObject?, error: NSError?) -> Void in
            
            if ((error) != nil) {
                NSLog("%@",error!);
                self.leaveChatRoomCallback()
                return;
            }
            
            self.chatRoomController.loadNextPageMessages()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "newMessage", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "newPresenceEvent", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "didSetDeviceToken", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "messageError", object: nil)
    }
    
    func reloadTable() {
        self.tableView.reloadData()
        self.view.setNeedsDisplay()
    }
    
    func initStyle() {
        topBar.backgroundColor = ColorConstants.chatNavBackground
        chatBar.backgroundColor = ColorConstants.chatNavBackground
        topBarDivider.backgroundColor = ColorConstants.chatNavBorder
        chatBarDivider.backgroundColor = ColorConstants.chatNavBorder
        numActiveLabel.textColor = ColorConstants.textSecondary
        
        sendEnabled = false
        
        let loadOverlay = LoadingView.instanceFromNib()
        loadOverlay.loadingTextLabel.text = "Leaving chat..."
        loadingView.addSubview(loadOverlay)
        loadOverlay.autoPinEdgesToSuperviewEdges()
    }
    
    func subscribe() {
        Utilities.appDelegate().subscribeToPubNubChannel(chatRoomController.chatRoomId)
        Utilities.appDelegate().subscribeToPubNubPushChannel(chatRoomController.chatRoomId)
    }
    
    func setupObervers() {
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChatViewController.deselectTextView)))
        chatBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChatViewController.selectTextView)))
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserverForName("newMessage", object: nil, queue: nil) { (notification: NSNotification) -> Void in
            self.chatRoomController.receiveMessage(notification.object as! Message)
            self.scrollToBottom(true)
        }
        NSNotificationCenter.defaultCenter().addObserverForName("newPresenceEvent", object: nil, queue: nil) { (notification: NSNotification) -> Void in
            self.chatRoomController.receivePresenceEvent(notification.object as! Presence)
            self.scrollToBottom(true)
        }
        NSNotificationCenter.defaultCenter().addObserverForName("didSetDeviceToken", object: nil, queue: nil) { (notification: NSNotification) -> Void in
            self.subscribe()
        }
        NSNotificationCenter.defaultCenter().addObserverForName("messageError", object: nil, queue: nil) { (notification: NSNotification) -> Void in
            let messageIndex = self.chatRoomController.findMyFirstSentMessageIndexMatchingText((notification.object as! Message).body)
            (self.chatRoomController.allActions[messageIndex] as! Message).status = MessageStatus.Error
            self.tableView.reloadData()
        }
    }
    
    @IBAction func backTap() {
        
        UIView.animateWithDuration(0.33) { () -> Void in
            self.loadingView.alpha = 1
        }
        
        PFCloud.callFunctionInBackground("leaveChatRoom", withParameters: ["aliasId": myAlias().objectId!, "pubkey": EnvironmentConstants.pubNubPublishKey, "subkey": EnvironmentConstants.pubNubSubscribeKey]) { (object: AnyObject?, error: NSError?) -> Void in
            
            if (error != nil) {
                UIView.animateWithDuration(0.333) { () -> Void in
                    self.loadingView.alpha = 0
                }
                return
            }
            
            self.leaveChatRoomCallback()
        }
    }
    
    func leaveChatRoomCallback() {
        if let chatRoom = ChatRoom.fetchSingleRoom() {
            Answers.logCustomEventWithName("Left Chat", customAttributes: ["chatRoomId": chatRoom.objectId, "lengthOfStay":chatRoom.myAlias.joinedAt.timeIntervalSinceNow * -1 * 1000])
            Utilities.appDelegate().managedObjectContext.deleteObject(chatRoom)
            Utilities.appDelegate().saveContext()
        }
        Utilities.appDelegate().unsubscribeFromPubNubChannel(self.chatRoomController.chatRoomId)
        Utilities.appDelegate().unsubscribeFromPubNubPushChannel(self.chatRoomController.chatRoomId)
        self.delegate?.closeChat()
    }
    
    @IBAction func sendPress() {
        if (!sendEnabled) {
            return
        }
        
        let text = textView.text!
        clearTextView()
        
        sendText(text)
    }
    
    @IBAction func dotsPress() {
        self.performSegueWithIdentifier("popoverMenuSegue", sender: self)
    }
    
    func myAlias() -> Alias {
        return chatRoomController.myAlias
    }
    
    func sendText(text: String) {
        let message = Message.createMessage(text, alias: myAlias(), timestamp: nil, status:MessageStatus.Sent)
        sendMessage(message)
        chatRoomController.addMessage(message)
        Answers.logCustomEventWithName("Sent Message", customAttributes: ["chatRoomId": chatRoomController.chatRoomId, "lifeCycle":"SENT"])
    }
    
    func clearTextView() {
        textView.text = ""
        textViewDidChange(textView)
        numberInputTextLines = 0
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
    
    func scrollToBottom(animated: Bool) {
        if (chatRoomController.allActions.count == 0) {
            return;
        }
        
        let indexPath = NSIndexPath(forRow: chatRoomController.allActions.count - 1, inSection:0)
        self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition:UITableViewScrollPosition.Bottom, animated:animated)
    }
    
    func scrollToEventIndex(index: Int, animated: Bool) {
        let indexPath = NSIndexPath(forRow: index, inSection:0)
        self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition:UITableViewScrollPosition.Top, animated:animated)
    }
    
    // Keyboard Delegate Methods
    
    func keyboardWillShow(notification: NSNotification) {
        
        if (!textView.isFirstResponder()) {
            return
        }
        
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
        return chatRoomController.allActions.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let event = chatRoomController.allActions[indexPath.row]
        if let message = event as? Message {
            let cell = tableView.dequeueReusableCellWithIdentifier("ChatCell", forIndexPath: indexPath) as! ChatCell
            cell.setMessageText(message.body, alias: message.alias, isOutbound: chatRoomController.isMyMessage(message), showAliasLabel: chatRoomController.shouldShowAliasLabelForMessageIndex(indexPath.row), showAliasIcon: chatRoomController.shouldShowAliasIconForMessageIndex(indexPath.row), status: message.status)
            return cell
        }
        else if let presenceEvent = event as? Presence {
            let cell = tableView.dequeueReusableCellWithIdentifier("PresenceCell", forIndexPath: indexPath) as! PresenceCell
            cell.setAlias(presenceEvent.alias, andAction: presenceEvent.action, isMine: chatRoomController.isMyPresenceEvent(presenceEvent))
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let action = chatRoomController.allActions[indexPath.row]
        if let message = action as? Message {
            
            var cellHeight = ChatCell.rowHeightForText(message.body, withAliasLabel: chatRoomController.shouldShowAliasLabelForMessageIndex(indexPath.row)) + 2
            
            let nextMessage = chatRoomController.findFirstMessageAfterIndex(indexPath.row)
            if (nextMessage?.alias.objectId != message.alias.objectId) {
                cellHeight += messageVerticalBuffer
            }
            
            return cellHeight
        }
        else if let _ = action as? Presence {
            return 36
        }
        return 0
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (chatRoomController.allMessagesLoaded || chatRoomController.loadMessageCallInFlight) {
            return
        }
        
        if (tableView.contentOffset.y <= 50) {
            chatRoomController.loadNextPageMessages()
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
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "popoverMenuSegue" {
            let popoverViewController = segue.destinationViewController as! OptionsMenuController
            popoverViewController.delegate = self
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController!.delegate = self
        }
        if segue.identifier == "popoverFeedbackSegue" {
            let popoverViewController = segue.destinationViewController as! FeedbackViewController
            popoverViewController.delegate = self
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController!.delegate = self
        }

    }
    
    // MARK: - UIPopoverPresentationControllerDelegate method
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        
        // Force popover style
        return UIModalPresentationStyle.None
    }
    
    func selectedFeedback() {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.performSegueWithIdentifier("popoverFeedbackSegue", sender: self)
    }
    
    func didUpdateEvents() {
        reloadTable()
    }
    
    func didUpdateActiveAliases(aliases:[Alias]) {
        if (aliases.count == 0) {
            numActiveLabel.text = "Waiting for others..."
        }
        else {
            numActiveLabel.text = "\(aliases.count) members"
        }
    }
    
    func didAddEvents(events:[AnyObject], reloaded:Bool, firstLoad: Bool) {
        reloadTable()
        if (!reloaded || firstLoad) { scrollToBottom(true) }
        if (reloaded && !firstLoad) { scrollToEventIndex(events.count, animated: false) }
    }
    
    func shouldClose() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
