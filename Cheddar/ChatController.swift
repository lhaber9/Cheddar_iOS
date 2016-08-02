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
    func showOverlay()
    func hideOverlay()
    func showOverlayContents(viewController: UIViewController)
    func hideOverlayContents()
}

class ChatController: UIViewController, UIAlertViewDelegate, ChatListControllerDelegate, ChatViewControllerDelegate, ChatRoomDelegate, ChatAlertDelegate, OptionsOverlayViewDelegate {
    
    weak var delegate: ChatDelegate!
    
    var reachability:Reachability?
    @IBOutlet var networkErrorAlertView: UIView!
    @IBOutlet var showingNetworkErrorAlertConstraint: NSLayoutConstraint!
    
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var listContainer: UIView!
    @IBOutlet var chatContainer: UIView!
    
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
    
    var confirmLeaveAlertView = UIAlertView()
    var confirmLogoutAlertView = UIAlertView()
    
    var chatListController: ChatListController!
    var chatViewController: ChatViewController!
    var chatAlertController: ChatAlertController!
    
    var optionOverlayController: OptionsOverlayViewController!
    
    var chatAdded = false
    var isDraggingChatAlert = false
    var isShowingList = true
    var alertTimerId: String!
    var leavingChatRoom: ChatRoom!
    
    override func viewDidLoad() {
        topBar.backgroundColor = ColorConstants.chatNavBackground
        topBarDivider.backgroundColor = ColorConstants.chatNavBorder
        numActiveLabel.textColor = ColorConstants.textSecondary
        
        initChatListVC()
        initChatAlertVC()
        initChatViewVC()
        
        networkErrorAlertView.backgroundColor = ColorConstants.colorAccent
        
        NSNotificationCenter.defaultCenter().addObserverForName("didSetDeviceToken", object: nil, queue: nil) { (notification: NSNotification) in
            self.chatListController.refreshRooms()
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName("applicationDidBecomeActive", object: nil, queue: nil) { (notification: NSNotification) in
            self.reachabilityChanged(nil)
        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatController.reachabilityChanged), name: kReachabilityChangedNotification, object: nil)
        
        let r = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(ChatController.slideFromLeft(_:)))
        r.edges = UIRectEdge.Left
        view.addGestureRecognizer(r)
        
        confirmLeaveAlertView = UIAlertView(title: "Are you sure?", message: "Leaving the chat will mean you lose your nickname", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Leave")
        
        confirmLogoutAlertView = UIAlertView(title: "Are you sure?", message: "Are you sure you want to logout", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Logout")
        
        reachability = Reachability.reachabilityForInternetConnection()
        reachability!.startNotifier();
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "didSetDeviceToken", object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: kReachabilityChangedNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "applicationDidBecomeActive", object: nil)
    }
    
    func reachabilityChanged(notification: NSNotification?) {
        let remoteHostStatus = reachability!.currentReachabilityStatus()
        if (remoteHostStatus == NotReachable) {
            UIView.animateWithDuration(0.15, animations: { 
                self.showingNetworkErrorAlertConstraint.priority = 950
                self.view.layoutIfNeeded()
            })
        } else {
            UIView.animateWithDuration(0.15, animations: {
                self.showingNetworkErrorAlertConstraint.priority = 200
                self.view.layoutIfNeeded()
            })
        }
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
        
        chatContainer.layer.shadowOpacity = 0.5
        chatContainer.layer.shadowColor = UIColor.blackColor().CGColor
        
        chatContainer.layer.shadowOffset = CGSizeMake(-1.5, 0)
        chatContainer.layer.shadowRadius = 8
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
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(1.5 * Double(NSEC_PER_SEC)))
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
            !isShowingList) {
            return true
        }
        return false
    }
    
    func askLogoutUser(object: AnyObject!) {
        optionOverlayController?.shouldClose()
        confirmLogoutAlertView.show()
    }
    
    func logoutUser() {
        CheddarRequest.logoutUser({
            self.optionOverlayController.shouldClose()
            Utilities.removeAllUserData()
            self.delegate.removeChat()
        }) { (error) in
            self.optionOverlayController.shouldClose()
        }
    }
    
    func linkToWebsite(object: AnyObject!) {
        
    }
    
    func showVersion(object: AnyObject!) {
        
    }
    
    // MARK: Button Actions
    @IBAction func slideFromLeft(recognizer: UIPanGestureRecognizer) {

        if (chatContainerFocusConstraint.priority == 200) {
            return
        }
        
        let point = recognizer.locationInView(view)
        
        if (recognizer.velocityInView(view).x > 1500) {
            chatContainerFocusConstraint.constant = 0;
            chatContainerFocusConstraint.priority = 200;
            showList()
            return
        }
        
        if (recognizer.state == UIGestureRecognizerState.Ended) {
            if (point.x > UIScreen.mainScreen().bounds.size.width / 2) {
                chatContainerFocusConstraint.constant = 0;
                chatContainerFocusConstraint.priority = 200;
                showList()
            } else {
                showChatRoom(chatViewController.chatRoom)
            }
            return
        }
        
        self.chatContainerFocusConstraint.constant = point.x;
        view.layoutIfNeeded()
    }
    
    @IBAction func hamburgerButtonTap() {
        showChatListOptions()
    }
    
    @IBAction func newChatButtonTap() {
        joinNextAndAnimate()
    }
    
    @IBAction func backButtonTap() {
        showList()
    }
    
    @IBAction func optionsButtonTap() {
        chatViewController.deselectTextView()
        showChatRoomViewOptions(chatViewController.chatRoom)
    }
    
    @IBAction func titleTap() {
        if (!isShowingList) {
            chatViewController.showRename()
        }
    }
    
    @IBAction func subTitleTap() {
        if (!isShowingList) {
            chatViewController.showActiveMembers()
        }
    }

    // MARK: ChatViewControllerDelegate
    
    func subscribe(chatRoom:ChatRoom) {
        Utilities.appDelegate().subscribeToPubNubChannel(chatRoom.objectId)
        Utilities.appDelegate().subscribeToPubNubPushChannel(chatRoom.objectId)
        chatRoom.delegate = self
    }
    
    func showChatRoomViewOptions(chatRoom:ChatRoom) {
        optionOverlayController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("OptionsOverlayViewController") as! OptionsOverlayViewController
        optionOverlayController.delegate = self
        
        optionOverlayController.buttonNames = ["Send Feedback", "Leave Group"]
        optionOverlayController.buttonData = [nil,chatRoom]
        optionOverlayController.buttonActions = [selectedFeedback, tryLeaveChatRoom]
        
        self.delegate!.showOverlay()
        self.delegate!.showOverlayContents(optionOverlayController)
        self.optionOverlayController.willShow()
    }
    
    func showList() {
        isShowingList = true
        chatListController.reloadRooms()
        UIView.animateWithDuration(0.333, animations: {
            self.chatContainerFocusConstraint.priority = 200
            self.listContainerFocusConstraint.priority = 900
            self.sublabelShowingConstraint.priority = 200
            self.sublabelHiddenConstraint.priority = 900
            self.sublabelView.alpha = 0
            if let selectedRow = self.chatListController.tableView.indexPathForSelectedRow {
                self.chatListController.tableView.deselectRowAtIndexPath(selectedRow, animated: true)
            }
            self.chatViewController?.deselectTextView()
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
        
        leavingChatRoom = nil
        delegate.showLoadingViewWithText("Leaving Chat...")
        
        CheddarRequest.leaveChatroom(alias.objectId!,
        successCallback: { (object) in
            
            Answers.logCustomEventWithName("Left Chat", customAttributes: ["chatRoomId": alias.chatRoomId, "lengthOfStay":alias.joinedAt.timeIntervalSinceNow * -1 * 1000])
            
            self.chatViewController.chatRoom = nil
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
        delegate.showOverlay()
    }
    
    func hideOverlay() {
        delegate.hideOverlay()
    }
    
    func showOverlayContents(viewController: UIViewController) {
        delegate.showOverlayContents(viewController)
    }
    
    func hideOverlayContents() {
        delegate.hideOverlayContents()
    }
    
    func selectedFeedback(object: AnyObject!) {
        optionOverlayController.willHide()
        hideOverlayContents()
        chatViewController.performSegueWithIdentifier("showFeedbackSegue", sender: self)
    }
    
    func tryLeaveChatRoom(object: AnyObject!) {
        leavingChatRoom = object as! ChatRoom
        optionOverlayController?.shouldClose()
        confirmLeaveAlertView.show()
    }
    
    // MARK: ChatListControllerDelegate
    
    func showChatListOptions() {
        optionOverlayController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("OptionsOverlayViewController") as! OptionsOverlayViewController
        optionOverlayController.delegate = self
        
        optionOverlayController.buttonNames = ["Logout", "Website","Version"]
        optionOverlayController.buttonData = [nil, nil, nil]
        optionOverlayController.buttonActions = [askLogoutUser, linkToWebsite, showVersion]
        
        self.delegate!.showOverlay()
        self.delegate!.showOverlayContents(optionOverlayController)
        self.optionOverlayController.willShow()
    }
    
    func forceCloseChat() {
//        Utilities.appDelegate().reinitalizeUser()
        delegate.removeChat()
    }
    
    func showChatRoom(chatRoom: ChatRoom) {
        isShowingList = false
        chatRoom.delegate = self
        chatViewController.chatRoom = chatRoom
        
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
                self.chatContainerFocusConstraint.constant = 0
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
                chatRoom.setUnreadMessages(false)
//                self.chatViewController.scrollToBottom(true)
            }
        })
    }
    
    // MARK: ChatRoomDelegate
    
    func didUpdateUnreadMessages(chatRoom: ChatRoom, areUnreadMessages: Bool) {
        if (!isCurrentChatRoom(chatRoom)) {
            chatListController.refreshRooms()
            return
        }
        
        if (chatViewController == nil) {
            return
        }
        
        chatViewController.updateLayout()
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
            if (!isShowingList) {
                showNewMessageAlert(chatRoom, chatEvent: chatEvent)
            }
            if (!isMine) {
                chatRoom.setUnreadMessages(true)
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
            chatRoom.setUnreadMessages(true)
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
            if (aliases.count == 1) {
                numActiveLabel.text = "\(aliases.count) member"
            }
            else {
                numActiveLabel.text = "\(aliases.count) members"
            }
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
    
    // MARK: UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if (buttonIndex == 1 && alertView.isEqual(confirmLeaveAlertView)) {
            leaveChatRoom(leavingChatRoom.myAlias)
        }
        if (buttonIndex == 1 && alertView.isEqual(confirmLogoutAlertView)) {
            logoutUser()
        }
    }

}