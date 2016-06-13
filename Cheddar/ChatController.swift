//
//  ChatController.swift
//  Cheddar
//
//  Created by Lucas Haber on 4/7/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Parse
import Crashlytics

protocol ChatDelegate: class {
    func removeChat()
    func showLoadingViewWithText(text:String)
    func hideLoadingView()
}

class ChatController: UIViewController, ChatListControllerDelegate, ChatViewControllerDelegate, ChatRoomDelegate, ChatAlertDelegate {
    
    weak var delegate: ChatDelegate!
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var listContainer: UIView!
    @IBOutlet var chatContainer: UIView!
    @IBOutlet var overlayContainer: UIView!
    @IBOutlet var overlayContentsContainer: UIView!
    var contentsController: UIViewController!
    
    @IBOutlet var listContainerFocusConstraint: NSLayoutConstraint!
    @IBOutlet var chatContainerFocusConstraint: NSLayoutConstraint!
    
    @IBOutlet var sublabelShowingConstraint: NSLayoutConstraint!
    @IBOutlet var sublabelHiddenConstraint: NSLayoutConstraint!
    
    @IBOutlet var notificationConstraint: NSLayoutConstraint!
    @IBOutlet var notificationContainer: UIView!
    
    @IBOutlet var topBar: UIView!
    @IBOutlet var topBarDivider: UIView!
    
    @IBOutlet var hamburgerButton: UIButton!
    @IBOutlet var newChatButton: UIButton!
    
    @IBOutlet var backButton: UIButton!
    @IBOutlet var optionsButton: UIButton!
    
    @IBOutlet var sublabelView: UIView!
    @IBOutlet var numActiveLabel: UILabel!
    
    var chatListController: ChatListController!
    var chatViewController: ChatViewController!
    var chatAlertController: ChatAlertController!
    
    var chatAdded = false
    var isDraggingChatAlert = false
    var alertTimerId: String!
    
    override func viewDidLoad() {
        topBar.backgroundColor = ColorConstants.chatNavBackground
        topBarDivider.backgroundColor = ColorConstants.chatNavBorder
        numActiveLabel.textColor = ColorConstants.textSecondary
        
        initChatListVC()
        initChatAlertVC()
        initChatViewVC()
        
        NSNotificationCenter.defaultCenter().addObserverForName("didSetDeviceToken", object: nil, queue: nil) { (notification: NSNotification) in
            self.chatListController.refreshRooms()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
         NSNotificationCenter.defaultCenter().removeObserver(self, name: "didSetDeviceToken", object: nil)
    }
    
    func initChatListVC() {
        chatListController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("ChatListController") as! ChatListController
        chatListController.delegate = self
        addChildViewController(chatListController)
        listContainer.addSubview(chatListController.view)
        chatListController.view.autoPinEdgesToSuperviewEdges()
    }
    
    func initChatAlertVC() {
        chatAlertController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("ChatAlertController") as! ChatAlertController
        chatAlertController.delegate = self
        addChildViewController(chatAlertController)
        notificationContainer.addSubview(chatAlertController.view)
        chatAlertController.view.autoPinEdgesToSuperviewEdges()
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action:#selector(self.dragMessageAlert))
        notificationContainer.addGestureRecognizer(panGestureRecognizer)
    }
    
    func initChatViewVC() {
        chatViewController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
        chatViewController.delegate = self
        
    }
    
    func isShowingList() -> Bool {
        if (listContainerFocusConstraint.priority > 500) {
            return true
        }
        return false
    }
    
    func joinNextAndAnimate() {
        
        var chatRoom: ChatRoom!
        var animationComplete = false
        
        CheddarRequest.joinNextAvailableChatRoom(CheddarRequest.currentUserId()!,
                                                 maxOccupancy: 5,
        successCallback: { (object) in
        
            let alias = Alias.createOrUpdateAliasFromParseObject(object as! PFObject)
            chatRoom = ChatRoom.createWithMyAlias(alias)
            Utilities.appDelegate().saveContext()
            Utilities.appDelegate().subscribeToPubNubChannel(chatRoom.objectId)
            Utilities.appDelegate().subscribeToPubNubPushChannel(chatRoom.objectId)
            Answers.logCustomEventWithName("Joined Chat", customAttributes: nil)
            self.chatListController.reloadRooms()
            chatRoom.loadNextPageMessages()
            if (animationComplete) {
                self.showChatRoom(chatRoom)
            }
            
        }) { (error) in
            NSLog("Error Joining Room: %@", error)
            self.chatListController.reloadRooms()
            self.delegate.hideLoadingView()
            return
        }
        
        performJoinChatAnimation { () -> Void in
            animationComplete = true
            if (chatRoom != nil) {
                self.showChatRoom(chatRoom)
            }
        }
    }
    
    func performJoinChatAnimation(callback: () -> Void) {
        delegate.showLoadingViewWithText("Joining Chat...")
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(4 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            callback()
        }
    }
    
    func showNewMessageAlert(chatRoom:ChatRoom, chatEvent:ChatEvent) {
        if (chatEvent.alias.objectId == chatRoom.myAlias.objectId){
            return
        }
        
        chatAlertController.chatRoom = chatRoom
        chatAlertController.chatEvent = chatEvent
        chatAlertController.refreshView()
        
        showNewMessageAlert()
    }
    
    func showNewMessageAlert() {
        UIView.animateWithDuration(0.125) {
            self.notificationConstraint.constant = 70
            self.view.layoutIfNeeded()
        }
        
        let thisAlertTimerId = NSUUID.init().UUIDString
        alertTimerId = thisAlertTimerId
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(4 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            
            if (!self.isDraggingChatAlert && thisAlertTimerId == self.alertTimerId) {
                self.hideNewMessageAlert()
            }
        }
    }
    
    func hideNewMessageAlert() {
        UIView.animateWithDuration(0.125) {
            self.notificationConstraint.constant = 0
            self.view.layoutIfNeeded()
        }
    }
    
    func dragMessageAlert(panGestureRecognizer: UIPanGestureRecognizer) {
        isDraggingChatAlert = true
        let touchLocation = panGestureRecognizer.locationInView(self.view)
        self.notificationConstraint.constant = touchLocation.y
        
        if (touchLocation.y > 90) {
            self.notificationConstraint.constant = 90
        }
        
        if (panGestureRecognizer.state == UIGestureRecognizerState.Ended) {
            isDraggingChatAlert = false
            if (touchLocation.y < (self.notificationContainer.frame.height / 2)) {
                hideNewMessageAlert()
            }
            else {
                showNewMessageAlert()
            }
        }
    }
    
    func isCurrentChatRoom(chatRoom: ChatRoom) -> Bool {
        if (chatRoom.objectId == chatViewController.myAlias()?.chatRoomId &&
            !isShowingList()) {
            return true
        }
        return false
    }
    
    // MARK: Button Actions
    
    @IBAction func hamburgerButtonTap() {
    }
    
    @IBAction func newChatButtonTap() {
        joinNextAndAnimate()
    }
    
    @IBAction func backButtonTap() {
        showList()
    }
    
    @IBAction func optionsButtonTap() {
        chatViewController.deselectTextView()
        chatViewController.showOptions()
    }
    
    @IBAction func titleTap() {
        if (!isShowingList()) {
            chatViewController.showRename()
        }
    }
    
    @IBAction func subTitleTap() {
        if (!isShowingList()) {
            chatViewController.showActiveMembers()
        }
    }

    // MARK: ChatViewControllerDelegate
    
    func subscribe(chatRoom:ChatRoom) {
        Utilities.appDelegate().subscribeToPubNubChannel(chatRoom.objectId)
        Utilities.appDelegate().subscribeToPubNubPushChannel(chatRoom.objectId)
        chatRoom.delegate = self
    }
    
    func showList() {
        self.chatListController.refreshRooms()
        self.chatListController.reloadRooms()
        UIView.animateWithDuration(0.333, animations: {
            self.chatContainerFocusConstraint.priority = 200
            self.listContainerFocusConstraint.priority = 900
            self.sublabelShowingConstraint.priority = 200
            self.sublabelHiddenConstraint.priority = 900
            self.sublabelView.alpha = 0
            if let selectedRow = self.chatListController.tableView.indexPathForSelectedRow {
                self.chatListController.tableView.deselectRowAtIndexPath(selectedRow, animated: true)
            }
            self.chatViewController.deselectTextView()
            self.hamburgerButton.enabled = true
            self.hamburgerButton.alpha = 1
            self.newChatButton.enabled = true
            self.newChatButton.alpha = 1
            self.backButton.enabled = false
            self.backButton.alpha = 0
            self.optionsButton.enabled = false
            self.optionsButton.alpha = 0
            self.titleLabel.text = "Groups"
            self.view.layoutIfNeeded()
        })
    }
    
    func leaveChatRoom(alias: Alias) {
        
        delegate.showLoadingViewWithText("Leaving Chat...")
        
        CheddarRequest.leaveChatroom(alias.objectId!,
        successCallback: { (object) in
            
            Answers.logCustomEventWithName("Left Chat", customAttributes: ["chatRoomId": alias.chatRoomId, "lengthOfStay":alias.joinedAt.timeIntervalSinceNow * -1 * 1000])
            
            self.forceLeaveChatRoom(alias)
            
        }) { (error) in
            NSLog("Error leaving chatroom: %@", error)
            self.delegate.hideLoadingView()
            return
        }
    }
    
    func forceLeaveChatRoom(alias: Alias) {
        ChatRoom.removeChatRoom(alias.chatRoomId)
        Utilities.appDelegate().saveContext()
        delegate.hideLoadingView()
        showList()
    }
    
    func showOverlay() {
        UIView.animateWithDuration(0.33, animations: {
            self.overlayContainer.hidden = false
            self.overlayContainer.alpha = 1
            self.view.layoutIfNeeded()
        })
    }
    
    func hideOverlay() {
        UIView.animateWithDuration(0.33, animations: {
            self.overlayContainer.alpha = 0
            self.view.layoutIfNeeded()
        }) { (completed: Bool) in
            self.overlayContainer.hidden = true
        }
    }
    
    func showOverlayContents(viewController: UIViewController) {
        addChildViewController(viewController)
        overlayContentsContainer.addSubview(viewController.view)
        viewController.view.autoPinEdgesToSuperviewEdges()
        contentsController = viewController
        self.view.layoutIfNeeded()
        
        UIView.animateWithDuration(0.33, animations: {
            self.overlayContentsContainer.hidden = false
            self.overlayContentsContainer.alpha = 1
            self.view.layoutIfNeeded()
        })
    }
    
    func hideOverlayContents() {
        UIView.animateWithDuration(0.33, animations: {
            self.overlayContentsContainer.alpha = 0
            self.view.layoutIfNeeded()
        }) { (completed: Bool) in
            self.overlayContentsContainer.hidden = true
            self.contentsController?.view.removeFromSuperview()
            self.contentsController?.removeFromParentViewController()
            self.contentsController = nil
        }
    }
    
    // MARK: ChatListControllerDelegate
    
    func forceCloseChat() {
//        Utilities.appDelegate().reinitalizeUser()
        delegate.removeChat()
    }
    
    func showChatRoom(chatRoom: ChatRoom) {
        chatRoom.delegate = self
        chatViewController.chatRoom = chatRoom
        chatViewController.reloadTable()
        
        hideNewMessageAlert()
        
        if (!chatAdded) {
            self.addChildViewController(self.chatViewController)
            self.chatContainer.addSubview(self.chatViewController.view)
            self.chatViewController.view.autoPinEdgesToSuperviewEdges()
            chatAdded = true
        }
        
        self.chatViewController.scrollToBottom(false)
        
        view.layoutIfNeeded()
        
        dispatch_async(dispatch_get_main_queue(), {
            UIView.animateWithDuration(0.333, animations:{
                self.chatContainerFocusConstraint.priority = 900
                self.listContainerFocusConstraint.priority = 200
                self.sublabelShowingConstraint.priority = 900
                self.sublabelHiddenConstraint.priority = 200
                self.sublabelView.alpha = 1
                self.hamburgerButton.enabled = false
                self.hamburgerButton.alpha = 0
                self.newChatButton.enabled = false
                self.newChatButton.alpha = 0
                self.backButton.enabled = true
                self.backButton.alpha = 1
                self.optionsButton.enabled = true
                self.optionsButton.alpha = 1
                self.titleLabel.text = chatRoom.name
                self.view.layoutIfNeeded()
            }) { (error: Bool) in
                self.delegate.hideLoadingView()
//                self.chatViewController.scrollToBottom(true)
            }
        })
    }
    
    // MARK: ChatRoomDelegate
    
    func didUpdateUnreadMessages(areUnreadMessages: Bool) {
        if (chatViewController == nil) {
            return
        }
        
        UIView.animateWithDuration(0.333) {
            if (self.chatViewController.isUnreadMessages) {
                self.chatViewController.unreadMessagesView.alpha = 1
            }
            else {
                self.chatViewController.unreadMessagesView.alpha = 0
            }
        }
    }
    
    func didUpdateName(chatRoom:ChatRoom) {
        if (!isCurrentChatRoom(chatRoom)) {
            chatListController.refreshRooms()
            return
        }
        
        self.titleLabel.text = chatRoom.name
    }
    
    func didUpdateEvents(chatRoom:ChatRoom) {
        if (!isCurrentChatRoom(chatRoom)) {
            chatListController.refreshRooms()
            return
        }
        
        chatViewController.reloadTable()
        chatListController.refreshRooms()
    }
    
    func didAddEvent(chatRoom:ChatRoom, chatEvent:ChatEvent, isMine: Bool) {
        if (!isCurrentChatRoom(chatRoom)) {
            if (!isShowingList()) {
                showNewMessageAlert(chatRoom, chatEvent: chatEvent)
            }
            if (!isMine) {
                chatRoom.areUnreadMessages = true
            }
            chatListController.refreshRooms()
            return
        }
        
        if (chatEvent.type == ChatEventType.NameChange.rawValue) {
            didUpdateName(chatRoom)
        }
        
        didUpdateEvents(chatRoom)
        let lastCellHeight = chatViewController.tableView(chatViewController.tableView, heightForRowAtIndexPath: NSIndexPath(forRow: chatRoom.chatEvents.count - 1, inSection: 0))
        
        if (chatViewController.isNearBottom(lastCellHeight + 55)) {
            chatViewController.scrollToBottom(true)
        }
        else if (!isMine) {
            chatRoom.areUnreadMessages = true
        }
    }
    
    func didUpdateActiveAliases(chatRoom:ChatRoom, aliases:NSSet) {
        if (!isCurrentChatRoom(chatRoom)) {
            return
        }
        
        if (aliases.count == 0) {
            numActiveLabel.text = "Waiting for others..."
        }
        else {
            numActiveLabel.text = "\(aliases.count) members"
        }
    }
    
    func didReloadEvents(chatRoom:ChatRoom, eventCount:Int, firstLoad: Bool) {
        if (!isCurrentChatRoom(chatRoom)) {
            return
        }
        
        chatViewController.reloadTable()
        chatListController.refreshRooms()
        if (firstLoad) { chatViewController.scrollToBottom(true) }
        else { chatViewController.scrollToEventIndex(eventCount, animated: false) }
    }
}