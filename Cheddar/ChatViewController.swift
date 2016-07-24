
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
    func subscribe(chatRoom:ChatRoom)
    func leaveChatRoom(alias: Alias)
    func forceLeaveChatRoom(alias: Alias)
    func showOverlay()
    func hideOverlay()
    func showOverlayContents(viewController: UIViewController)
    func hideOverlayContents()
}

class ChatViewController: UIViewController, UITextViewDelegate, UIPopoverPresentationControllerDelegate, UIAlertViewDelegate,  OptionsOverlayViewDelegate, FeedbackViewDelegate, RenameChatDelegate, ActiveMembersDelegate, UITableViewDelegate {
    
    weak var delegate: ChatViewControllerDelegate?
    
    @IBOutlet var textView: UITextView!
    @IBOutlet var placeholderLabel: UILabel!
    @IBOutlet var chatBarDivider: UIView!
    @IBOutlet var chatBar: UIView!
    @IBOutlet var unreadMessagesView: UIView!
    
    @IBOutlet var chatBarBottomConstraint: NSLayoutConstraint!
    @IBOutlet var chatBarHeightConstraint: NSLayoutConstraint!
    @IBOutlet var chatBarTextTopConstraint: NSLayoutConstraint!
    
    @IBOutlet var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var tableViewTopFixedConstraint: NSLayoutConstraint!
    @IBOutlet var tableViewTopVariableConstraint: NSLayoutConstraint!
    
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var tableView: UITableView!
    
    var optionOverlayController: OptionsOverlayViewController!
    var confirmLeaveAlertView = UIAlertView()
    
    var messageVerticalBuffer:CGFloat = 15
    var chatBarHeightDefault:CGFloat = 56
    var previousTextRect = CGRectZero
    var dragPosition: CGFloat!
    
    var chatRoom: ChatRoom! {
        didSet {
            if (chatRoom == nil) {
                return
            }
        
            self.reloadTable()
            self.setupChatroom()
        }
    }
    
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
        tableView.registerNib(UINib(nibName: "NameChangeCell", bundle: nil), forCellReuseIdentifier: "NameChangeCell")
        
        textView.delegate = self
        
        initStyle()
        
        setupObervers()
        setupChatroom()
        
        confirmLeaveAlertView = UIAlertView(title: "Are you sure?", message: "Leaving the chat will mean you lose your nickname", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Leave")
        
        reloadTable()
    }
    
    func updateLayout() {
        UIView.animateWithDuration(0.333) {
            if (self.chatRoom != nil && self.chatRoom.areUnreadMessages.boolValue) {
                self.unreadMessagesView.alpha = 1
            }
            else {
                self.unreadMessagesView.alpha = 0
            }
        }
    }
    
    func setupChatroom() {
        chatRoom.reloadActiveAlaises()
        
        CheddarRequest.findAlias(myAlias().objectId,
            successCallback: { (object) in
                
                if (self.chatRoom.chatEvents.count == 0) {
                    self.chatRoom.loadNextPageMessages()
                }
                else {
                    self.chatRoom.reloadMessages()
                }
                
                self.delegate?.subscribe(self.chatRoom)
                
            }) { (error) in
                NSLog("%@",error)
                let alias = self.myAlias()
                self.chatRoom = nil
                self.delegate?.forceLeaveChatRoom(alias)
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func reloadTable() {
        chatRoom.sortChatEvents()
        self.tableView?.reloadData()
    }
    
    func initStyle() {
        chatBar.backgroundColor = ColorConstants.chatNavBackground
        chatBarDivider.backgroundColor = ColorConstants.chatNavBorder
        
        unreadMessagesView.backgroundColor = ColorConstants.textPrimary
        unreadMessagesView.layer.cornerRadius = 11
        
        sendEnabled = false
        
        textView.textColor = ColorConstants.textPrimary
        
//        unreadMessagesView.layer.shadowRadius = 5
        
    }
    
    func setupObervers() {
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChatViewController.deselectTextView)))
        chatBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(ChatViewController.selectTextView)))
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
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
    
    func myAlias() -> Alias! {
        return chatRoom?.myAlias
    }
    
    // MARK: Button Action
    
    @IBAction func sendPress() {
        if (!sendEnabled) {
            return
        }
        
        let text = textView.text!
        clearTextView()
        
        sendText(text)
        scrollToBottom(true)
    }
    
    @IBAction func scrollToBottom() {
        scrollToBottom(true)
    }
    
    func showRename() {
        self.delegate?.showOverlay()
        self.performSegueWithIdentifier("showRenameSegue", sender: self)
    }
    
    func showActiveMembers() {
        self.delegate?.showOverlay()
        self.performSegueWithIdentifier("showActiveMembersSegue", sender: self)
    }
    
    // MARK: Actions
    
    func sendText(text: String) {
        let message = ChatEvent.createEvent(text, alias: myAlias(), createdAt: NSDate(), type: ChatEventType.Message.rawValue, status: ChatEventStatus.Sent)
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
    
    func scrollToBottom(animated: Bool) {
        if (chatRoom.chatEvents.count == 0) {
            return;
        }
        
        let indexPath = NSIndexPath(forRow: chatRoom.chatEvents.count - 1, inSection:0)
        self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition:UITableViewScrollPosition.Bottom, animated:animated)
    }
    
    func scrollToEventIndex(index: Int, animated: Bool) {
        dispatch_async(dispatch_get_main_queue(), {
            let indexPath = NSIndexPath(forRow: index, inSection:0)
            self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition:UITableViewScrollPosition.Top, animated:animated)
        })
        
    }
    
    // MARK: Keyboard Delegate Methods
    
    func keyboardWillShow(notification: NSNotification) {
        
        if (!textView.isFirstResponder()) {
            return
        }
        
        if (tableView?.contentSize.height > tableView?.frame.size.height) {
            tableViewHeightConstraint?.priority = 900
            tableViewTopVariableConstraint?.priority = 900
            tableViewTopFixedConstraint?.priority = 200
        }
        else {
            tableViewHeightConstraint?.priority = 200
            tableViewTopVariableConstraint?.priority = 200
            tableViewTopFixedConstraint?.priority = 900
        }
        self.view.layoutIfNeeded()
        
        let keyboardHeight: CGFloat = (notification.userInfo![UIKeyboardFrameEndUserInfoKey]?.CGRectValue.height)!
        
        self.chatBarBottomConstraint.constant = keyboardHeight
        self.view.layoutIfNeeded()
        self.scrollToBottom(true)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        UIView.animateWithDuration(0.333) { () -> Void in
            self.chatBarBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: TableView Delegate Methods
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatRoom.chatEvents.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let event = chatRoom.sortedChatEvents[indexPath.row]
        if (event.type == ChatEventType.Message.rawValue) {
            let cell = tableView.dequeueReusableCellWithIdentifier("ChatCell", forIndexPath: indexPath) as! ChatCell
            dispatch_async(dispatch_get_main_queue(), {
                let options: [String:AnyObject] = [ "text": event.body,
                                                    "alias": event.alias,
                                                    "isOutbound": self.chatRoom.isMyChatEvent(event),
                                                    "showAliasLabel": self.chatRoom.shouldShowAliasLabelForMessageIndex(indexPath.row),
                                                    "showAliasIcon": self.chatRoom.shouldShowAliasIconForMessageIndex(indexPath.row),
                                                    "status": event.status]
            
                cell.setMessageOptions(options)
            })
            return cell
        }
        else if (event.type == ChatEventType.Presence.rawValue) {
            let cell = tableView.dequeueReusableCellWithIdentifier("PresenceCell", forIndexPath: indexPath) as! PresenceCell
            cell.setAlias(event.alias, andAction: event.body, isMine: chatRoom.isMyChatEvent(event))
            return cell
        }
        else if (event.type == ChatEventType.NameChange.rawValue) {
            let cell = tableView.dequeueReusableCellWithIdentifier("NameChangeCell", forIndexPath: indexPath) as! NameChangeCell
            cell.setEvent(event)
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let event = chatRoom.sortedChatEvents[indexPath.row]
        if (event.type == ChatEventType.Message.rawValue) {
            
            var cellHeight = ChatCell.rowHeightForText(event.body, withAliasLabel: chatRoom.shouldShowAliasLabelForMessageIndex(indexPath.row)) + 2
            
            let nextMessage = chatRoom.findFirstMessageAfterIndex(indexPath.row)
            if (nextMessage?.alias.objectId != event.alias.objectId) {
                cellHeight += messageVerticalBuffer
            }
            
            return cellHeight
        }
        else if (event.type == ChatEventType.Presence.rawValue) {
            return 36
        }
        else if (event.type == ChatEventType.NameChange.rawValue) {
            return 44
        }
        
        return 0
    }
    
    // MARK: Scroll View Delegate Methods
    
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
            chatRoom.setUnreadMessages(false)
        }
        
        if (tableView.contentOffset.y <= 50) {
            chatRoom.loadNextPageMessages()
        }
    }
    
    // MARK: TextViewDelegate
    
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
    
    // MARK: OptionsOverlayViewDelegate
    
    func showOptions() {
        optionOverlayController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("OptionsOverlayViewController") as! OptionsOverlayViewController
        optionOverlayController.delegate = self
        
        self.delegate!.showOverlay()
        self.delegate!.showOverlayContents(optionOverlayController)
        self.optionOverlayController.willShow()
    }
    
    func selectedFeedback() {
        self.performSegueWithIdentifier("showFeedbackSegue", sender: self)
    }
    
    func willCloseOptions() {
        self.optionOverlayController?.willHide()
    }
    
    func shouldClosePopover() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func shouldCloseOverlayContents() {
        self.delegate!.hideOverlayContents()
    }
    
    func shouldCloseOverlay() {
        self.delegate!.hideOverlay()
    }
    
    func tryLeaveChatRoom() {
        confirmLeaveAlertView.show()
    }
    
    // MARK: FeedbackViewDelegate
    
    func shouldCloseAll() {
        shouldClosePopover()
        shouldCloseOverlay()
        shouldCloseOverlayContents()
    }
    
    // MARK: RenameChatDelegate
    
    func currentChatRoomName() -> String! {
        return chatRoom.name
    }
    
    // MARK: ActiveMembersDelegate
    
    func currentChatRoom() -> ChatRoom {
        return chatRoom
    }
    
    // MARK: UIPopoverPresentationControllerDelegate
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showFeedbackSegue" {
            let popoverViewController = segue.destinationViewController as! FeedbackViewController
            popoverViewController.delegate = self
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController!.delegate = self
        }
        else if segue.identifier == "showRenameSegue" {
            let popoverViewController = segue.destinationViewController as! RenameChatController
            popoverViewController.delegate = self
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController!.delegate = self
        }
        else if segue.identifier == "showActiveMembersSegue" {
            let popoverViewController = segue.destinationViewController as! ActiveMembersController
            popoverViewController.delegate = self
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController!.delegate = self
        }
    }
    
    func popoverPresentationControllerWillDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        shouldCloseAll()
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        
        // Force popover style
        return UIModalPresentationStyle.None
    }
    
    // MARK: UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if (buttonIndex == 1 && alertView.isEqual(confirmLeaveAlertView)) {
            let alias = myAlias()
            chatRoom = nil
            delegate!.leaveChatRoom(alias)
        }
    }

    
}
