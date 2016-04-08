
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
    func didUpdateActiveAliases(aliases:[Alias])
    func leaveChatRoom(alias: Alias)
    func showList()
}

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, ChatRoomDelegate, UIAlertViewDelegate {
    
    weak var delegate: ChatViewControllerDelegate?
    
    @IBOutlet var textView: UITextView!
    @IBOutlet var placeholderLabel: UILabel!
    @IBOutlet var chatBarDivider: UIView!
    @IBOutlet var chatBar: UIView!
    @IBOutlet var unreadMessagesView: UIView!
    
    @IBOutlet var chatBarBottomConstraint: NSLayoutConstraint!
    @IBOutlet var chatBarHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var chatBarTextTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var sendButton: UIButton!
    
    @IBOutlet var tableView: UITableView!
    
//    var confirmLeaveAlertView = UIAlertView()
    
    var messageVerticalBuffer:CGFloat = 15
    var chatBarHeightDefault:CGFloat = 56
    var previousTextRect = CGRectZero
    var dragPosition: CGFloat!
    var isUnreadMessages = false {
        didSet {
            if (self.unreadMessagesView == nil) {
                return
            }
            
            UIView.animateWithDuration(0.333) {
                if (self.isUnreadMessages) {
                    self.unreadMessagesView.alpha = 1
                }
                else {
                    self.unreadMessagesView.alpha = 0
                }
            }
        }
    }
    
//    var chatRoomController:ChatRoomController!
    
    var chatRoom: ChatRoom! {
        didSet {
            reloadTable()
            setupChatroom()
        }
    }
    
//    var myAlias: Alias!
//    var chatRoomId: String!
    
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
                if (self.numberInputTextLines > 1) {
                    self.textView.textContainerInset.top = 4
                    self.chatBarTextTopConstraint.constant = 6
                }
                else {
                    self.textView.textContainerInset.top = 8
                    self.chatBarTextTopConstraint.constant = 12
                }
                
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
        
//        confirmLeaveAlertView = UIAlertView(title: "Are you sure?", message: "Leaving the chat will mean you lose your nickname", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Leave")
        
        initStyle()
        
        setupObervers()
        
        setupChatroom()
    }
    
    func setupChatroom() {
        chatRoom.delegate = self
        chatRoom.reloadActiveAlaises()
        
        PFCloud.callFunctionInBackground("findAlias", withParameters: ["aliasId": chatRoom.myAlias.objectId]) { (object: AnyObject?, error: NSError?) -> Void in
            
            if ((error) != nil) {
                NSLog("%@",error!);
                //                self.leaveChatRoomCallback()
                return;
            }
            
            self.chatRoom.loadNextPageMessages()
            self.subscribe()
        }
    }
    
    deinit {
        
        NSLog("HERE")
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "didSetDeviceToken", object: nil)
    }
    
    func reloadTable() {
        self.tableView?.reloadData()
        self.view.layoutIfNeeded()
    }
    
    func initStyle() {
        chatBar.backgroundColor = ColorConstants.chatNavBackground
        chatBarDivider.backgroundColor = ColorConstants.chatNavBorder
        
        unreadMessagesView.backgroundColor = ColorConstants.textPrimary
        unreadMessagesView.layer.cornerRadius = 11
        
        sendEnabled = false
        
        textView.textColor = ColorConstants.textPrimary
    }
    
    func isNearBottom(distance: CGFloat) -> Bool {
        let scrollViewHeight = tableView.frame.size.height;
        let scrollContentSizeHeight = tableView.contentSize.height;
        let scrollOffset = tableView.contentOffset.y;
        
        if (scrollOffset + scrollViewHeight >= scrollContentSizeHeight - distance) {
            return true
        }
        
        return false
    }
    
    func subscribe() {
        Utilities.appDelegate().subscribeToPubNubChannel(chatRoom.objectId)
        Utilities.appDelegate().subscribeToPubNubPushChannel(chatRoom.objectId)
    }
    
    func setupObervers() {
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChatViewController.deselectTextView)))
        chatBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChatViewController.selectTextView)))
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserverForName("didSetDeviceToken", object: nil, queue: nil) { (notification: NSNotification) -> Void in
            self.subscribe()
        }
    }
    
    @IBAction func sendPress() {
        if (!sendEnabled) {
            return
        }
        
        let text = textView.text!
        clearTextView()
        
        sendText(text)
        scrollToBottom(true)
    }
    
    func myAlias() -> Alias {
        return chatRoom.myAlias
    }
    
    func sendText(text: String) {
        let message = Message.createMessage(text, alias: myAlias(), timestamp: nil, status:MessageStatus.Sent)
        chatRoom.sendMessage(message)
        Answers.logCustomEventWithName("Sent Message", customAttributes: ["chatRoomId": chatRoom.objectId, "lifeCycle":"SENT"])
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
    
    @IBAction func scrollToBottom() {
        scrollToBottom(true)
    }
    
    func scrollToBottom(animated: Bool) {
        if (chatRoom.allActions.count == 0) {
            return;
        }
        
        let indexPath = NSIndexPath(forRow: chatRoom.allActions.count - 1, inSection:0)
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
        return chatRoom.allActions.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let event = chatRoom.allActions[indexPath.row]
        if let message = event as? Message {
            let cell = tableView.dequeueReusableCellWithIdentifier("ChatCell", forIndexPath: indexPath) as! ChatCell
            cell.setMessageText(message.body, alias: message.alias, isOutbound: chatRoom.isMyMessage(message), showAliasLabel: chatRoom.shouldShowAliasLabelForMessageIndex(indexPath.row), showAliasIcon: chatRoom.shouldShowAliasIconForMessageIndex(indexPath.row), status: message.status)
            return cell
        }
        else if let presenceEvent = event as? Presence {
            let cell = tableView.dequeueReusableCellWithIdentifier("PresenceCell", forIndexPath: indexPath) as! PresenceCell
            cell.setAlias(presenceEvent.alias, andAction: presenceEvent.action, isMine: chatRoom.isMyPresenceEvent(presenceEvent))
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let action = chatRoom.allActions[indexPath.row]
        if let message = action as? Message {
            
            var cellHeight = ChatCell.rowHeightForText(message.body, withAliasLabel: chatRoom.shouldShowAliasLabelForMessageIndex(indexPath.row)) + 2
            
            let nextMessage = chatRoom.findFirstMessageAfterIndex(indexPath.row)
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
    
    
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        dragPosition = scrollView.contentOffset.y
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        dragPosition = nil
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (scrollView.isEqual(textView) && numberInputTextLines <= 4) {
            textView.contentOffset.y = 0
            return
        }
        
        if (dragPosition != nil) {
            if (scrollView.contentOffset.y < dragPosition - 15) {
                deselectTextView()
            }
            else {
                dragPosition = scrollView.contentOffset.y
            }
        }
        
        if (isNearBottom(5)) {
            isUnreadMessages = false
        }
        
        if (tableView.contentOffset.y <= 50) {
            chatRoom.loadNextPageMessages()
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
    
    // MARK: - UIPopoverPresentationControllerDelegate method
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        
        // Force popover style
        return UIModalPresentationStyle.None
    }

    func didUpdateEvents() {
        reloadTable()
    }
    
    func didUpdateActiveAliases(aliases:[Alias]) {
        delegate?.didUpdateActiveAliases(aliases)
    }
    
    func didReloadEvents(events:[AnyObject], firstLoad: Bool) {
        reloadTable()
        if (firstLoad) { scrollToBottom(true) }
        else { scrollToEventIndex(events.count, animated: false) }
    }
    
    func didAddMessage(isMine: Bool) {
        reloadTable()
        if (isNearBottom(ChatCell.singleRowHeight * 3)) { scrollToBottom(true) }
        else if(!isMine) { isUnreadMessages = true }
    }
    
    func didAddPresence(isMine: Bool) {
        reloadTable()
        if (isNearBottom(ChatCell.singleRowHeight * 3)) { scrollToBottom(true) }
        else if(!isMine) { isUnreadMessages = true }
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
//        if (buttonIndex == 1 && alertView.isEqual(confirmLeaveAlertView)) {
//            delegate?.leaveChatRoom(chatRoomController.myAlias)
//        }
    }
}
