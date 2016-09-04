//
//  ChatController.swift
//  Cheddar
//
//  Created by Lucas Haber on 4/7/16.
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

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


protocol ChatDelegate: class {
    func removeChat()
    func showLoadingViewWithText(_ text:String)
    func hideLoadingView()
    func showOverlay()
    func hideOverlay()
    func showOverlayContents(_ viewController: UIViewController)
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
    
    @IBOutlet var notificationShowingConstraint: NSLayoutConstraint!
    @IBOutlet var notificationHeightConstraint: NSLayoutConstraint!
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
    var confirmReportUserAlertView = UIAlertView()
    var confirmBlockUserAlertView = UIAlertView()
    
    var chatListController: ChatListController!
    var chatViewController: ChatViewController!
    var chatAlertController: ChatAlertController!
    
    var optionOverlayController: OptionsOverlayViewController!
    
    var isDraggingChatAlert = false
    var isShowingList = true
    var alertTimerId: String!
    var leavingChatRoom: ChatRoom!
    var reportedAlias: Alias!
    var messageAlertTouchStartLocation:CGPoint!
    var notificationHeight: CGFloat!
    
    override func viewDidLoad() {
        topBar.backgroundColor = ColorConstants.chatNavBackground
        topBarDivider.backgroundColor = ColorConstants.chatNavBorder
        numActiveLabel.textColor = ColorConstants.textPrimary
        
        initChatListVC()
        initChatAlertVC()
        initChatViewVC()
        
        networkErrorAlertView.backgroundColor = ColorConstants.colorAccent
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "didSetDeviceToken"), object: nil, queue: nil) { (notification: Notification) in
            self.chatListController.refreshRooms()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "applicationDidBecomeActive"), object: nil, queue: nil) { (notification: Notification) in
            self.reachabilityChanged(nil)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ChatController.reachabilityChanged), name: NSNotification.Name.reachabilityChanged, object: nil)
        
        let r = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(ChatController.slideFromLeft(_:)))
        r.edges = UIRectEdge.left
        view.addGestureRecognizer(r)
        
        confirmLeaveAlertView = UIAlertView(title: "Are you sure?", message: "You wont be able to rejoin this chat room once you leave", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Leave")
        
        confirmLogoutAlertView = UIAlertView(title: "Are you sure?", message: "Are you sure you want to logout", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Logout")

        confirmReportUserAlertView = UIAlertView(title: "Are you sure?", message: "Are you sure you want to report this user for inappropriate content. Additional content reports may be sent to cheddar@neucheddar.com", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Report")
        
        confirmBlockUserAlertView = UIAlertView(title: "Block User?", message: "Do you want to block this user? You will be immediately removed from this chatroom and never be matched with this user again.", delegate: self, cancelButtonTitle: "No", otherButtonTitles: "Yes")
        
        reachability = Reachability.forInternetConnection()
        reachability!.startNotifier()
        
        titleLabel.adjustsFontSizeToFitWidth = true
        
        checkMaxRooms()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "didSetDeviceToken"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.reachabilityChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "applicationDidBecomeActive"), object: nil)
    }
    
    func reachabilityChanged(_ notification: Notification?) {
        let remoteHostStatus = reachability!.currentReachabilityStatus()
        if (remoteHostStatus == NotReachable) {
            UIView.animate(withDuration: 0.15, animations: { 
                self.showingNetworkErrorAlertConstraint.priority = 950
                self.view.layoutIfNeeded()
            })
        } else {
            UIView.animate(withDuration: 0.15, animations: {
                self.showingNetworkErrorAlertConstraint.priority = 200
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func initChatListVC() {
        chatListController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "ChatListController") as! ChatListController
        chatListController.delegate = self
        addChildViewController(chatListController)
        listContainer.addSubview(chatListController.view)
        chatListController.view.autoPinEdgesToSuperviewEdges()
    }
    
    func initChatAlertVC() {
        chatAlertController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "ChatAlertController") as! ChatAlertController
        chatAlertController.delegate = self
        addChildViewController(chatAlertController)
        notificationContainer.addSubview(chatAlertController.view)
        chatAlertController.view.autoPinEdgesToSuperviewEdges()
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action:#selector(self.dragMessageAlert))
        notificationContainer.addGestureRecognizer(panGestureRecognizer)
        
        notificationHeight = notificationContainer.frame.height
    }
    
    func initChatViewVC() {
        chatViewController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
        chatViewController.delegate = self
        
        chatContainer.layer.shadowOpacity = 0.5
        chatContainer.layer.shadowColor = UIColor.black.cgColor
        
        chatContainer.layer.shadowOffset = CGSize(width: -1.5, height: 0)
        chatContainer.layer.shadowRadius = 8
        
        self.addChildViewController(self.chatViewController)
        self.chatContainer.addSubview(self.chatViewController.view)
        self.chatViewController.view.autoPinEdgesToSuperviewEdges()

    }
    
    func checkMaxRooms() {
        UIView.animate(withDuration: 0.333) { 
            if (ChatRoom.fetchAll().count >= 5) {
                self.newChatButton.setImage(UIImage(named: "MaxChats"), for: UIControlState())
            }
            else {
                self.newChatButton.setImage(UIImage(named: "NewChat"), for: UIControlState())
            }
        }
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
            
            self.chatListController.reloadRooms()
            chatRoom.loadNextPageMessages()
            if (animationComplete) {
                self.showChatRoom(chatRoom)
            }
            
            self.checkMaxRooms()
        }) { (error) in
            NSLog("Error Joining Room: %@", error as NSError)
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
    
    func performJoinChatAnimation(_ callback: @escaping () -> Void) {
        delegate.showLoadingViewWithText("Joining Chat...")
        
        let delayTime = DispatchTime.now() + Double(Int64(1.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            callback()
        }
    }
    
    func showNewMessageAlert(_ chatRoom:ChatRoom, chatEvent:ChatEvent) {
        if (chatEvent.alias.objectId == chatRoom.myAlias.objectId){
            return
        }
        
        chatAlertController.chatRoom = chatRoom
        chatAlertController.chatEvent = chatEvent
        chatAlertController.refreshView()
        
        showNewMessageAlert()
    }
    
    func showNewMessageAlert() {
        UIView.animate(withDuration: 0.125) {
            self.notificationHeightConstraint.constant = self.notificationHeight
            self.notificationShowingConstraint.constant = 0
            self.notificationShowingConstraint.priority = 950
            self.view.layoutIfNeeded()
        }
        
        let thisAlertTimerId = UUID.init().uuidString
        alertTimerId = thisAlertTimerId
        let delayTime = DispatchTime.now() + Double(Int64(4 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            
            if (!self.isDraggingChatAlert && thisAlertTimerId == self.alertTimerId) {
                self.hideNewMessageAlert()
            }
        }
    }
    
    func hideNewMessageAlert() {
        UIView.animate(withDuration: 0.125) {
            self.notificationHeightConstraint.constant = self.notificationHeight
            self.notificationShowingConstraint.constant = 0
            self.notificationShowingConstraint.priority = 200
            self.view.layoutIfNeeded()
        }
    }
    
    func dragMessageAlert(_ panGestureRecognizer: UIPanGestureRecognizer) {
        isDraggingChatAlert = true
        let touchLocation = panGestureRecognizer.location(in: self.view)
        let velocity = panGestureRecognizer.velocity(in: self.view).y
        if (messageAlertTouchStartLocation == nil) {
            messageAlertTouchStartLocation = touchLocation
        }
        
        let notificationLocation = touchLocation.y - messageAlertTouchStartLocation.y + 80
        if (notificationLocation <= notificationHeight) {
            self.notificationHeightConstraint.constant = notificationHeight
            self.notificationShowingConstraint.constant = notificationLocation - notificationHeight
        } else {
            self.notificationHeightConstraint.constant = notificationLocation
            self.notificationShowingConstraint.constant = 0
        }
        
        if (notificationLocation > 105) {
            self.notificationHeightConstraint.constant = 105 + notificationLocation / 25
        }
        
        if (panGestureRecognizer.state == UIGestureRecognizerState.ended) {
            isDraggingChatAlert = false
            if (velocity < -200) {
                hideNewMessageAlert()
                return
            }
            
            if (notificationLocation < (self.notificationHeight / 2)) {
                hideNewMessageAlert()
            }
            else {
                showNewMessageAlert()
            }
        }
    }
    
    func isCurrentChatRoom(_ chatRoom: ChatRoom) -> Bool {
        if (chatRoom.objectId == chatViewController.myAlias()?.chatRoomId &&
            !isShowingList) {
            return true
        }
        return false
    }
    
    func askLogoutUser(_ object: AnyObject!) {
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
    
    func showChatListButtons() {
        self.hamburgerButton.isEnabled = true
        self.hamburgerButton.alpha = 1
        self.newChatButton.isEnabled = true
        self.newChatButton.alpha = 1
        self.backButton.isEnabled = false
        self.backButton.alpha = 0
        self.optionsButton.isEnabled = false
        self.optionsButton.alpha = 0
    }
    
    func showChatViewButtons() {
        self.hamburgerButton.isEnabled = false
        self.hamburgerButton.alpha = 0
        self.newChatButton.isEnabled = false
        self.newChatButton.alpha = 0
        self.backButton.isEnabled = true
        self.backButton.alpha = 1
        self.optionsButton.isEnabled = true
        self.optionsButton.alpha = 1
    }
    
    // MARK: Button Actions
    @IBAction func slideFromLeft(_ recognizer: UIPanGestureRecognizer) {

        if (chatContainerFocusConstraint.priority == 200) {
            return
        }
        
        let point = recognizer.location(in: view)
        
        if (recognizer.velocity(in: view).x > 1500) {
            chatContainerFocusConstraint.constant = 0;
            chatContainerFocusConstraint.priority = 200;
            showList()
            return
        }
        
        if (recognizer.state == UIGestureRecognizerState.ended) {
            if (point.x > UIScreen.main.bounds.size.width / 2) {
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
        if (ChatRoom.fetchAll().count >= 5) {
            checkMaxRooms()
            UIAlertView(title: "Maxiumum Rooms Reached", message: "You must leave a chatroom before joining another", delegate: self, cancelButtonTitle: "OK").show()
            return
        }
        
        checkMaxRooms()
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
            showRename(nil)
        }
    }
    
    @IBAction func subTitleTap() {
//        if (!isShowingList) {
//            chatViewController.showActiveMembers()
//        }
        titleTap()
    }

    func showRename(_ object: AnyObject!) {
        optionOverlayController?.shouldClose()
        chatViewController.showRename()
    }
    
    func deleteEvent(_ object: AnyObject!) {
        optionOverlayController?.shouldClose()
        let deleteEvent = object as! ChatEvent
        CheddarRequest.sendDeleteChatEvent(chatViewController.myAlias().objectId, chatEventId: deleteEvent.objectId
            , successCallback: { (object) in
            
                let alias = Alias.createOrUpdateAliasFromParseObject(object as! PFObject)
                Utilities.appDelegate().saveContext()
                
                self.didUpdateEvents(ChatRoom.fetchById(alias.chatRoomId))
                
        }) { (error) in
            
        }
    }
    
    // MARK: ChatViewControllerDelegate
    
    func showDeleteMessageOptions(_ chatEvent:ChatEvent) {
        optionOverlayController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "OptionsOverlayViewController") as! OptionsOverlayViewController
        optionOverlayController.delegate = self
        
        optionOverlayController.buttonNames = ["Delete"]
        optionOverlayController.buttonData = [chatEvent]
        optionOverlayController.buttonActions = [deleteEvent as! (Optional<AnyObject>) -> ()]
        
        self.delegate!.showOverlay()
        self.delegate!.showOverlayContents(optionOverlayController)
        self.optionOverlayController.willShow()
    }
    
    func reportAlias(_ alias: Alias) {
        reportedAlias = alias
        optionOverlayController?.shouldClose()
        dismiss(animated: true, completion: nil)
        confirmReportUserAlertView.show()
    }
    
    func sendReportUserRequest(_ reportedAlias: Alias) {
        
        CheddarRequest.sendReportUser(reportedAlias.objectId,
                                      chatRoomId: reportedAlias.chatRoomId,
        successCallback: { (object) in
            
        }) { (error) in
            
        }
    }
    
    func subscribe(_ chatRoom:ChatRoom) {
        Utilities.appDelegate().subscribeToPubNubChannel(chatRoom.objectId)
        Utilities.appDelegate().subscribeToPubNubPushChannel(chatRoom.objectId)
        chatRoom.delegate = self
    }
    
    func showChatRoomViewOptions(_ chatRoom:ChatRoom) {
        optionOverlayController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "OptionsOverlayViewController") as! OptionsOverlayViewController
        optionOverlayController.delegate = self
        
        optionOverlayController.buttonNames = ["Leave Group", "Change Room Name", "View Active Members", "Send Feedback"]
        optionOverlayController.buttonData = [chatRoom,nil,nil,chatViewController.myAlias()]
        optionOverlayController.buttonActions = [tryLeaveChatRoom as! (Optional<AnyObject>) -> (), showRename as! (Optional<AnyObject>) -> (), showActiveMembers as! (Optional<AnyObject>) -> (), selectedFeedback as! (Optional<AnyObject>) -> ()]
        
        self.delegate!.showOverlay()
        self.delegate!.showOverlayContents(optionOverlayController)
        self.optionOverlayController.willShow()
    }
    
    func showList() {
        isShowingList = true
        chatListController.reloadRooms()
        UIView.animate(withDuration: 0.333, animations: {
            self.chatContainerFocusConstraint.priority = 200
            self.listContainerFocusConstraint.priority = 900
            self.sublabelShowingConstraint.priority = 200
            self.sublabelHiddenConstraint.priority = 900
            self.sublabelView.alpha = 0
            if let selectedRow = self.chatListController.tableView.indexPathForSelectedRow {
                self.chatListController.tableView.deselectRow(at: selectedRow, animated: true)
            }
            self.chatViewController?.deselectTextView()
            
            self.showChatListButtons()
            
            self.titleLabel.text = "Messages"
            self.view.layoutIfNeeded()
        })
    }
    
    func leaveChatRoom(_ alias: Alias) {
        
        leavingChatRoom = nil
        delegate.showLoadingViewWithText("Leaving Chat...")
        
        CheddarRequest.leaveChatroom(alias,
        successCallback: { (object) in
            
            self.chatViewController.chatRoom = nil
            self.forceLeaveChatRoom(alias)
            self.checkMaxRooms()
        }) { (error) in
            NSLog("Error leaving chatroom: %@", error as NSError)
            self.delegate.hideLoadingView()
            return
        }
    }
    
    func forceLeaveChatRoom(_ alias: Alias) {
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
    
    func showOverlayContents(_ viewController: UIViewController) {
        delegate.showOverlayContents(viewController)
    }
    
    func hideOverlayContents() {
        delegate.hideOverlayContents()
    }
    
    func selectedFeedback(_ object: AnyObject!) {
        optionOverlayController.willHide()
        hideOverlayContents()
        if (object == nil) {
            chatListController.performSegue(withIdentifier: "showFeedbackSegue", sender: self)
            return
        }
        chatViewController.performSegue(withIdentifier: "showFeedbackSegue", sender: self)
    }
    
    func tryLeaveChatRoom(_ object: AnyObject!) {
        leavingChatRoom = object as! ChatRoom
        optionOverlayController?.shouldClose()
        confirmLeaveAlertView.show()
    }
    
    func showActiveMembers(_ object: AnyObject!) {
        optionOverlayController?.willHide()
        chatViewController.showActiveMembers()
    }
    
    // MARK: ChatListControllerDelegate
    
    func showChatListOptions() {
        optionOverlayController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "OptionsOverlayViewController") as! OptionsOverlayViewController
        optionOverlayController.delegate = self
        
        optionOverlayController.buttonNames = ["Logout", "Send Feedback"]
        optionOverlayController.buttonData = [nil, nil]
        optionOverlayController.buttonActions = [askLogoutUser as! (Optional<AnyObject>) -> (), selectedFeedback as! (Optional<AnyObject>) -> ()]
        
        self.delegate!.showOverlay()
        self.delegate!.showOverlayContents(optionOverlayController)
        self.optionOverlayController.willShow()
    }
    
    func forceCloseChat() {
//        Utilities.appDelegate().reinitalizeUser()
        delegate.removeChat()
    }
    
    func showChatRoom(_ chatRoom: ChatRoom) {
        isShowingList = false
        chatRoom.delegate = self
        chatViewController.chatRoom = chatRoom
        
        view.layoutIfNeeded()
        self.chatViewController.scrollToBottom(false)
        
        DispatchQueue.main.async(execute: {
            UIView.animate(withDuration: 0.333, animations:{
                self.chatContainerFocusConstraint.constant = 0
                self.chatContainerFocusConstraint.priority = 900
                self.listContainerFocusConstraint.priority = 200
                self.sublabelShowingConstraint.priority = 900
                self.sublabelHiddenConstraint.priority = 200
                self.sublabelView.alpha = 1
                self.titleLabel.text = chatRoom.name
                
                self.showChatViewButtons()
                self.view.layoutIfNeeded()
            }) { (error: Bool) in
                self.delegate.hideLoadingView()
                chatRoom.setUnreadMessages(false)
//                self.chatViewController.scrollToBottom(true)
            }
        })
    }
    
    // MARK: ChatRoomDelegate
    
    func didUpdateUnreadMessages(_ chatRoom: ChatRoom, areUnreadMessages: Bool) {
        if (!isCurrentChatRoom(chatRoom)) {
            chatListController.refreshRooms()
            return
        }
        
        if (chatViewController == nil) {
            return
        }
        
        chatViewController.updateLayout()
    }
    
    func didUpdateName(_ chatRoom:ChatRoom) {
        if (!isCurrentChatRoom(chatRoom)) {
            chatListController.refreshRooms()
            return
        }
        
        self.titleLabel.text = chatRoom.name
    }
    
    func didUpdateEvents(_ chatRoom:ChatRoom) {
        if (!isCurrentChatRoom(chatRoom)) {
            chatListController.refreshRooms()
            return
        }
        
        chatViewController.invalidateHeightCache()
        
        chatViewController.reloadTable()
        chatListController.refreshRooms()
    }
    
    func didAddEvent(_ chatRoom:ChatRoom, chatEvent:ChatEvent, isMine: Bool) {
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
        let lastCellHeight = chatViewController.tableView(chatViewController.tableView, heightForRowAt: IndexPath(row: chatRoom.numberOfChatEvents() - 1, section: 0))
        
        if (chatViewController.isNearBottom(lastCellHeight + 55)) {
            chatViewController.scrollToBottom(true)
        }
        else if (!isMine) {
            chatRoom.setUnreadMessages(true)
        }
    }
    
    func didUpdateActiveAliases(_ chatRoom:ChatRoom, aliases:NSSet) {
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
    
    func didReloadEvents(_ chatRoom:ChatRoom, eventCount:Int, firstLoad: Bool) {
        if (!isCurrentChatRoom(chatRoom)) {
            return
        }
        
        chatViewController.invalidateHeightCache()
        
        chatViewController.reloadTable()
        chatListController.refreshRooms()
        if (firstLoad) {
            DispatchQueue.main.async(execute: {
                self.chatViewController.scrollToBottom(true)
            })
        }
        else {
            chatViewController.scrollToTopEventForLoading()
        }
    }
    
    func didChangeIsUnloadedMessages(_ chatRoom: ChatRoom) {
        chatViewController.invalidateHeightCache()
        
        chatViewController.reloadTable()
        chatListController.refreshRooms()
    }
    
    // MARK: UIAlertViewDelegate
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if (buttonIndex == 1 && alertView.isEqual(confirmLeaveAlertView)) {
            leaveChatRoom(leavingChatRoom.myAlias)
        } else if (buttonIndex == 1 && alertView.isEqual(confirmLogoutAlertView)) {
            logoutUser()
        } else if (buttonIndex == 1 && alertView.isEqual(confirmReportUserAlertView)) {
            sendReportUserRequest(reportedAlias)
            confirmBlockUserAlertView.show()
        } else if (buttonIndex == 1 && alertView.isEqual(confirmBlockUserAlertView)) {
            CheddarRequest.sendBlockUser(reportedAlias.userId,
                                         successCallback: { (object) in
                }, errorCallback: { (error) in
            })
            leaveChatRoom(chatViewController.myAlias())
        }
    }

}
