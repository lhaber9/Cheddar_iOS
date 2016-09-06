
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
    func reportAlias(alias: Alias)
    func subscribe(chatRoom:ChatRoom)
    func leaveChatRoom(alias: Alias)
    func forceLeaveChatRoom(alias: Alias)
    func showOverlay()
    func hideOverlay()
    func showOverlayContents(viewController: UIViewController)
    func hideOverlayContents()
    func showDeleteMessageOptions(chatEvent: ChatEvent)
}

class ChatViewController: UIViewController, UITextViewDelegate, UIPopoverPresentationControllerDelegate, FeedbackViewDelegate, RenameChatDelegate, ActiveMembersDelegate, ChatCellDelegate, UITableViewDelegate {
    
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
    
//    var refreshControl: UIRefreshControl!
    
    var topEventForLoading: ChatEvent!
    var messageVerticalBuffer:CGFloat = 15
    var chatBarHeightDefault:CGFloat = 56
    var previousTextRect = CGRectZero
    var dragPosition: CGFloat!
    
    var cellHeightCache = [Int:CGFloat]()
    
    var chatRoom: ChatRoom! {
        didSet {
            if (chatRoom == nil) {
                return
            }
        
            self.reloadTable()
            self.didUpdateChatRoom()
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
        tableView.registerNib(UINib(nibName: "ActivityIndicatorCell", bundle: nil), forCellReuseIdentifier: "ActivityIndicatorCell")
        
        textView.delegate = self
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ChatViewController.handleLongPress(_:)))
        longPressRecognizer.minimumPressDuration = 1
        tableView.addGestureRecognizer(longPressRecognizer)
        
        initStyle()
        
        setupObervers()
        
        invalidateHeightCache()
        reloadTable()
    }
    
    func handleLongPress(longPressRecognizer: UILongPressGestureRecognizer) {
        let point = longPressRecognizer.locationInView(tableView)
        
        let indexPath = tableView.indexPathForRowAtPoint(point)
        if (indexPath == nil) {
            NSLog("long press on table view but not on a row");
        } else if (longPressRecognizer.state == UIGestureRecognizerState.Began) {
            var row = indexPath!.row
            if (!chatRoom.allMessagesLoaded.boolValue) {
                if (row == 0) {
                    NSLog("long press on table view but on activity indicator cell");
                    return
                }
                row -= 1
            }
            
            let chatEvent = chatRoom.getSortedChatEvents()[row]
            if (chatEvent.type == ChatEventType.Message.rawValue) {
                showDeleteMessageOptions(chatEvent)
            }
        }
    }
    
    func showDeleteMessageOptions(chatEvent:ChatEvent) {
        delegate?.showDeleteMessageOptions(chatEvent)
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
    
    func loadNextPageMessages() {
        if (topEventForLoading == nil) {
            topEventForLoading = chatRoom.eventForIndex(0)
        }
        self.chatRoom?.loadNextPageMessages()
    }
    
    func didUpdateChatRoom() {
        chatRoom?.reloadActiveAlaises()
        invalidateHeightCache()
        
        CheddarRequest.findAlias((myAlias()?.objectId)!,
            successCallback: { (object) in
                
                if (self.chatRoom.numberOfChatEvents() == 0) {
                    self.loadNextPageMessages()
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
        if (chatRoom == nil) {
            return
        }
        
        let isNearBottomNow = isNearBottom(5)
        
        chatRoom.sortChatEvents()
        tableView?.reloadData()
        
        if (isNearBottomNow) {
            scrollToBottom(false)
        }
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
    
    func scrollToTopEventForLoading() {
        if (topEventForLoading == nil) {
            return
        }
        
        let index = chatRoom.indexForEvent(topEventForLoading)
        if (index > 0) {
            scrollToEventIndex(index - 1, animated: false)
        }
        topEventForLoading = nil
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
        
        Utilities.sendAnswersEvent("View Active Members", alias: myAlias(), attributes: [:])
        
        self.delegate?.showOverlay()
        self.performSegueWithIdentifier("showActiveMembersSegue", sender: self)
    }
    
    // MARK: Actions
    
    func sendText(text: String) {
        let message = ChatEvent.createEvent(text, alias: myAlias(), createdAt: NSDate(), type: ChatEventType.Message.rawValue, status: ChatEventStatus.Sent)
        chatRoom.sendMessage(message)
    }
    
    func clearTextView() {
        textView.text = ""
        textViewDidChange(textView)
        numberInputTextLines = 0
    }
    
    func deselectTextView() {
        textView?.resignFirstResponder()
    }
    
    func selectTextView() {
        textView?.becomeFirstResponder()
    }
    
    func scrollToBottom(animated: Bool) {
        if (chatRoom.numberOfChatEvents() == 0) {
            return;
        }
        
        var row = chatRoom.numberOfChatEvents() - 1
        if (!chatRoom.allMessagesLoaded.boolValue) {
            row += 1
        }
        
        let indexPath = NSIndexPath(forRow: row, inSection:0)
        self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition:UITableViewScrollPosition.Bottom, animated:animated)
    }
    
    func scrollToEventIndex(index: Int, animated: Bool) {
//        dispatch_async(dispatch_get_main_queue(), {
            let indexPath = NSIndexPath(forRow: index, inSection:0)
            self.tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition:UITableViewScrollPosition.Top, animated:animated)
//        })
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
        if (chatRoom == nil) {
            return 0
        }
        
        var count = chatRoom.numberOfChatEvents()
        if (!chatRoom.allMessagesLoaded.boolValue) {
           count += 1
        }
        
        return count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if (chatRoom == nil) {
            return UITableViewCell()
        }
        
        var index = indexPath.row
        let isFirstEvent = (index == 0)
        
        if (!chatRoom.allMessagesLoaded.boolValue) {
            if (isFirstEvent) {
                let cell = tableView.dequeueReusableCellWithIdentifier("ActivityIndicatorCell", forIndexPath: indexPath) as! ActivityIndicatorCell
                cell.activityIndicator.startAnimating()
                return cell
            }
            index -= 1
        }
        let event = chatRoom.getSortedChatEvents()[index]
        
        if (event.type == ChatEventType.Message.rawValue) {
            let cell = tableView.dequeueReusableCellWithIdentifier("ChatCell", forIndexPath: indexPath) as! ChatCell
            cell.delegate = self
            return cell
        }
        else if (event.type == ChatEventType.Presence.rawValue) {
            return tableView.dequeueReusableCellWithIdentifier("PresenceCell", forIndexPath: indexPath) as! PresenceCell
        }
        else if (event.type == ChatEventType.NameChange.rawValue) {
            return tableView.dequeueReusableCellWithIdentifier("NameChangeCell", forIndexPath: indexPath) as! NameChangeCell
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        var index = indexPath.row
        let isFirstEvent = (index == 0)
        
        if (!chatRoom.allMessagesLoaded.boolValue) {
            if (isFirstEvent) {
                return
            }
            index -= 1
        }
        let event = chatRoom.sortedChatEvents[index]
        
        if let messageCell = cell as? ChatCell {
            
            let viewSettings = chatRoom.getViewSettingsForMessageCellAtIndex(index)
            let showAliasLabel = viewSettings.0
            let showAliasIcon = viewSettings.1
            let bottomGapSize = viewSettings.2
            
            let options: [String:AnyObject] = [ "chatEvent": event,
                                                "isOutbound": self.chatRoom.isMyChatEvent(event),
                                                "showAliasLabel": showAliasLabel,
                                                "showAliasIcon": showAliasIcon,
                                                "showTimestampLabel": self.chatRoom.shouldShowTimestampLabelForEventIndex(index),
                                                "status": event.status,
                                                "bottomGapSize": bottomGapSize ]
            
            messageCell.setMessageOptions(options)
        }
        else if let presenceCell = cell as? PresenceCell {
            presenceCell.setAlias(event, showTimestamp: chatRoom.shouldShowTimestampLabelForEventIndex(index))
        }
        else if let nameChangeCell = cell as? NameChangeCell {
            nameChangeCell.setEvent(event, showTimestamp: chatRoom.shouldShowTimestampLabelForEventIndex(index), showBottomBuffer: index == chatRoom.numberOfChatEvents() - 1)
        }
    }
    
    func shouldUseHeightCacheForIndex(index: Int) -> Bool {
        if (index == chatRoom.numberOfChatEvents() - 1 || index == 0) {
            return false
        }
        
        return true
    }
    
    func setHeightToCache(index: Int, height: CGFloat) {
        if (!shouldUseHeightCacheForIndex(index)) {
            return
        }
        
        cellHeightCache[index] = height
    }
    
    func getHeightFromCache(index: Int) -> CGFloat! {
        if (!shouldUseHeightCacheForIndex(index)) {
            return nil
        }
        
        return cellHeightCache[index]
    }
    
    func invalidateHeightCache() {
        cellHeightCache = [Int:CGFloat]()
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        
        if (chatRoom == nil) {
            return 0
        }
        
        var index = indexPath.row
        if (!chatRoom.allMessagesLoaded.boolValue) {
            if (index == 0) {
                return ActivityIndicatorCell.activityIndicatorHeight
            }
            index -= 1
        }
        
        if (getHeightFromCache(index) != nil) {
            return getHeightFromCache(index)
        }
       
        let event = chatRoom.getSortedChatEvents()[index]
        var height: CGFloat = 0
        if (event.type == ChatEventType.Message.rawValue) {
            
            let viewSettings = chatRoom.getViewSettingsForMessageCellAtIndex(index)
            let showAliasLabel = viewSettings.0
            let bottomGapSize = viewSettings.2
            
            var cellHeight = ChatCell.rowHeightForText(event.body, withAliasLabel: showAliasLabel, withTimestampLabel: chatRoom.shouldShowTimestampLabelForEventIndex(index)) + 2
            
            cellHeight += bottomGapSize
            
            height = cellHeight
        }
        else if (event.type == ChatEventType.Presence.rawValue) {
            var cellHeight:CGFloat = 36
            if (chatRoom.shouldShowTimestampLabelForEventIndex(index)) {
                cellHeight += ChatCell.timestampLabelHeight
            }
            height = cellHeight
        }
        else if (event.type == ChatEventType.NameChange.rawValue) {
            var cellHeight:CGFloat = 37
            if (chatRoom.shouldShowTimestampLabelForEventIndex(index)) {
                cellHeight += ChatCell.timestampLabelHeight
            }
            if (index == chatRoom.numberOfChatEvents() - 1) {
                cellHeight += NameChangeCell.bottomBufferSize
            }
            height = cellHeight
        }
        
        if (index == 0 && chatRoom.allMessagesLoaded.boolValue) {
            height += ChatCell.bufferSize
        }
        
        setHeightToCache(index, height: height)
        
        return height
    }
    
    // MARK: Scroll View Delegate Methods
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        dragPosition = scrollView.contentOffset.y
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        dragPosition = nil
//        reloadTable()
//        scrollToTopEventForLoading()
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if (scrollView.isEqual(textView) && numberInputTextLines <= 4) {
            textView.contentOffset.y = 0
            return
        }
        
        if (dragPosition != nil) {
            if (tableView.contentOffset.y <= 75 && scrollView.contentOffset.y < dragPosition) {
                if (!chatRoom.allMessagesLoaded.boolValue) {
//                    refreshControl.beginRefreshing()
                    loadNextPageMessages()
                }
            }
            
            if (scrollView.contentOffset.y < dragPosition - 15) {
                deselectTextView()
            }
            
            dragPosition = scrollView.contentOffset.y
        }
        
        if (isNearBottom(5)) {
            chatRoom?.setUnreadMessages(false)
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
    
    func shouldClosePopover() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func shouldCloseOverlayContents() {
        self.delegate!.hideOverlayContents()
    }
    
    func shouldCloseOverlay() {
        self.delegate!.hideOverlay()
    }
    
    
    // MARK: FeedbackViewDelegate
    
    func shouldCloseAll() {
        shouldClosePopover()
        shouldCloseOverlay()
        shouldCloseOverlayContents()
    }
    
    // MARK: RenameChatDelegate
    
    func currentChatRoomName() -> String! {
        return chatRoom?.name
    }
    
    // MARK: ActiveMembersDelegate
    
    func currentChatRoom() -> ChatRoom {
        return chatRoom
    }
    
    func reportAlias(alias: Alias) {
        delegate?.reportAlias(alias)
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
            popoverViewController.preferredContentSize = CGSizeMake(300, popoverViewController.bottomBuffer() + popoverViewController.headerHeight() +
                (popoverViewController.tableView(UITableView(), heightForRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0)) * CGFloat(chatRoom.activeAliases.count)))
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
}
