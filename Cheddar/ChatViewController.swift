
//
//  ChatViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/6/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
//import Parse
import Crashlytics
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


protocol ChatViewControllerDelegate: class {
    func reportAlias(_ alias: Alias)
    func subscribe(_ chatRoom:ChatRoom)
    func leaveChatRoom(_ alias: Alias)
    func forceLeaveChatRoom(_ alias: Alias)
    func showOverlay()
    func hideOverlay()
    func showOverlayContents(_ viewController: UIViewController)
    func hideOverlayContents()
    func showDeleteMessageOptions(_ chatEvent: ChatEvent)
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
    var previousTextRect = CGRect.zero
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
            
            UIView.animate(withDuration: 0.333) { () -> Void in
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
            sendButton.isEnabled = sendEnabled
            placeholderLabel.isHidden = sendEnabled
        }
    }
    
    override func viewDidLoad() {
        tableView.register(UINib(nibName: "ChatCell", bundle: nil), forCellReuseIdentifier: "ChatCell")
        tableView.register(UINib(nibName: "PresenceCell", bundle: nil), forCellReuseIdentifier: "PresenceCell")
        tableView.register(UINib(nibName: "NameChangeCell", bundle: nil), forCellReuseIdentifier: "NameChangeCell")
        tableView.register(UINib(nibName: "ActivityIndicatorCell", bundle: nil), forCellReuseIdentifier: "ActivityIndicatorCell")
        
        textView.delegate = self
        
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ChatViewController.handleLongPress(_:)))
        longPressRecognizer.minimumPressDuration = 1
        tableView.addGestureRecognizer(longPressRecognizer)
        
        initStyle()
        
        setupObervers()
        
        invalidateHeightCache()
        reloadTable()
    }
    
    func handleLongPress(_ longPressRecognizer: UILongPressGestureRecognizer) {
        let point = longPressRecognizer.location(in: tableView)
        
        let indexPath = tableView.indexPathForRow(at: point)
        if (indexPath == nil) {
            NSLog("long press on table view but not on a row");
        } else if (longPressRecognizer.state == UIGestureRecognizerState.began) {
            var row = (indexPath! as NSIndexPath).row
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
    
    func showDeleteMessageOptions(_ chatEvent:ChatEvent) {
        delegate?.showDeleteMessageOptions(chatEvent)
    }
    
    func updateLayout() {
        UIView.animate(withDuration: 0.333) {
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
                self.delegate?.forceLeaveChatRoom(alias!)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func reloadTable() {
        if (chatRoom == nil) {
            return
        }
        
        let isNearBottomNow = isNearBottom(5)
        
        let _ = chatRoom.sortChatEvents()
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
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func isNearBottom(_ distance: CGFloat) -> Bool {
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
        
        if let index = chatRoom.indexForEvent(topEventForLoading) {
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
        self.performSegue(withIdentifier: "showRenameSegue", sender: self)
    }
    
    func showActiveMembers() {
        
        Utilities.sendAnswersEvent("View Active Members", alias: myAlias(), attributes: [:])
        
        self.delegate?.showOverlay()
        self.performSegue(withIdentifier: "showActiveMembersSegue", sender: self)
    }
    
    // MARK: Actions
    
    func sendText(_ text: String) {
        let message = ChatEvent.createEvent(text, alias: myAlias(), createdAt: Date(), type: ChatEventType.Message.rawValue, status: ChatEventStatus.Sent)
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
    
    func scrollToBottom(_ animated: Bool) {
        if (chatRoom.numberOfChatEvents() == 0) {
            return;
        }
        
        var row = chatRoom.numberOfChatEvents() - 1
        if (!chatRoom.allMessagesLoaded.boolValue) {
            row += 1
        }
        
        let indexPath = IndexPath(row: row, section:0)
        self.tableView.scrollToRow(at: indexPath, at:UITableViewScrollPosition.bottom, animated:animated)
    }
    
    func scrollToEventIndex(_ index: Int, animated: Bool) {
//        dispatch_async(dispatch_get_main_queue(), {
            let indexPath = IndexPath(row: index, section:0)
            self.tableView.scrollToRow(at: indexPath, at:UITableViewScrollPosition.top, animated:animated)
//        })
    }
    
    // MARK: Keyboard Delegate Methods
    
    func keyboardWillShow(_ notification: Notification) {
        
        if (!textView.isFirstResponder) {
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
        
        let keyboardHeight: CGFloat = (((notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.height)
        
        self.chatBarBottomConstraint.constant = keyboardHeight
        self.view.layoutIfNeeded()
        self.scrollToBottom(true)
    }
    
    func keyboardWillHide(_ notification: Notification) {
        UIView.animate(withDuration: 0.333) { () -> Void in
            self.chatBarBottomConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: TableView Delegate Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (chatRoom == nil) {
            return 0
        }
        
        var count = chatRoom.numberOfChatEvents()
        if (!chatRoom.allMessagesLoaded.boolValue) {
           count += 1
        }
        
        return count
    }
    
    
    private func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: IndexPath) -> UITableViewCell {
        if (chatRoom == nil) {
            return UITableViewCell()
        }
        
        var index = (indexPath as NSIndexPath).row
        let isFirstEvent = (index == 0)
        
        if (!chatRoom.allMessagesLoaded.boolValue) {
            if (isFirstEvent) {
                let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityIndicatorCell", for: indexPath) as! ActivityIndicatorCell
                cell.activityIndicator.startAnimating()
                return cell
            }
            index -= 1
        }
        let event = chatRoom.getSortedChatEvents()[index]
        
        if (event.type == ChatEventType.Message.rawValue) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath) as! ChatCell
            cell.delegate = self
            return cell
        }
        else if (event.type == ChatEventType.Presence.rawValue) {
            return tableView.dequeueReusableCell(withIdentifier: "PresenceCell", for: indexPath) as! PresenceCell
        }
        else if (event.type == ChatEventType.NameChange.rawValue) {
            return tableView.dequeueReusableCell(withIdentifier: "NameChangeCell", for: indexPath) as! NameChangeCell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        var index = (indexPath as NSIndexPath).row
        let isFirstEvent = (index == 0)
        
        if (!chatRoom.allMessagesLoaded.boolValue) {
            if (isFirstEvent) {
                return
            }
            index -= 1
        }
        let event = chatRoom.getSortedChatEvents()[index]
        
        if let messageCell = cell as? ChatCell {
            
            let viewSettings = chatRoom.getViewSettingsForMessageCellAtIndex(index)
            let showAliasLabel = viewSettings.0
            let showAliasIcon = viewSettings.1
            let bottomGapSize = viewSettings.2
            
            let options: [String:AnyObject] = [ "chatEvent": event,
                                                "isOutbound": self.chatRoom.isMyChatEvent(event) as AnyObject,
                                                "showAliasLabel": showAliasLabel as AnyObject,
                                                "showAliasIcon": showAliasIcon as AnyObject,
                                                "showTimestampLabel": self.chatRoom.shouldShowTimestampLabelForEventIndex(index) as AnyObject,
                                                "status": event.status as AnyObject,
                                                "bottomGapSize": bottomGapSize as AnyObject ]
            
            messageCell.setMessageOptions(options)
        }
        else if let presenceCell = cell as? PresenceCell {
            presenceCell.setAlias(event, showTimestamp: chatRoom.shouldShowTimestampLabelForEventIndex(index))
        }
        else if let nameChangeCell = cell as? NameChangeCell {
            nameChangeCell.setEvent(event, showTimestamp: chatRoom.shouldShowTimestampLabelForEventIndex(index), showBottomBuffer: index == chatRoom.numberOfChatEvents() - 1)
        }
    }
    
    func shouldUseHeightCacheForIndex(_ index: Int) -> Bool {
        if (index == chatRoom.numberOfChatEvents() - 1 || index == 0) {
            return false
        }
        
        return true
    }
    
    func setHeightToCache(_ index: Int, height: CGFloat) {
        if (!shouldUseHeightCacheForIndex(index)) {
            return
        }
        
        cellHeightCache[index] = height
    }
    
    func getHeightFromCache(_ index: Int) -> CGFloat! {
        if (!shouldUseHeightCacheForIndex(index)) {
            return nil
        }
        
        return cellHeightCache[index]
    }
    
    func invalidateHeightCache() {
        cellHeightCache = [Int:CGFloat]()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if (chatRoom == nil) {
            return 0
        }
        
        var index = (indexPath as NSIndexPath).row
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
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dragPosition = scrollView.contentOffset.y
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        dragPosition = nil
//        reloadTable()
//        scrollToTopEventForLoading()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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
    
    func textViewDidChange(_ textView: UITextView) {
        sendEnabled = (textView.text != "")
        
        let rows = Int(round((textView.contentSize.height - textView.textContainerInset.top - textView.textContainerInset.bottom) / textView.font!.lineHeight))
        
        if (numberInputTextLines != rows) {
            numberInputTextLines = rows
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            sendPress()
            return false;
        }
        
        return true;
    }
    
    // MARK: OptionsOverlayViewDelegate
    
    func shouldClosePopover() {
        self.dismiss(animated: true, completion: nil)
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
    
    func reportAlias(_ alias: Alias) {
        delegate?.reportAlias(alias)
    }
    
    // MARK: UIPopoverPresentationControllerDelegate
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFeedbackSegue" {
            let popoverViewController = segue.destination as! FeedbackViewController
            popoverViewController.delegate = self
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
            popoverViewController.popoverPresentationController!.delegate = self
        }
        else if segue.identifier == "showRenameSegue" {
            let popoverViewController = segue.destination as! RenameChatController
            popoverViewController.delegate = self
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
            popoverViewController.popoverPresentationController!.delegate = self
        }
        else if segue.identifier == "showActiveMembersSegue" {
            let popoverViewController = segue.destination as! ActiveMembersController
            popoverViewController.delegate = self
            
            var height = popoverViewController.bottomBuffer() + popoverViewController.headerHeight()
            height += (popoverViewController.tableView.rowHeight * CGFloat(chatRoom.activeAliases.count))
            
            popoverViewController.preferredContentSize = CGSize(width: 300, height: height)
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
            popoverViewController.popoverPresentationController!.delegate = self
        }
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        shouldCloseAll()
        return true
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        
        // Force popover style
        return UIModalPresentationStyle.none
    }
}
