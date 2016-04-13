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
    func showLoadingViewWithText(text:String)
    func hideLoadingView()
}

class ChatController: UIViewController, UIPopoverPresentationControllerDelegate, OptionsMenuControllerDelegate, FeedbackViewDelegate, ChatListControllerDelegate, ChatViewControllerDelegate, UIAlertViewDelegate, ChatRoomDelegate, ChatAlertDelegate {
    
    weak var delegate: ChatDelegate!
    
    @IBOutlet var listContainer: UIView!
    @IBOutlet var chatContainer: UIView!
    
    @IBOutlet var listContainerFocusConstraint: NSLayoutConstraint!
    @IBOutlet var chatContainerFocusConstraint: NSLayoutConstraint!
    
    @IBOutlet var sublabelShowingConstraint: NSLayoutConstraint!
    @IBOutlet var sublabelHiddenConstraint: NSLayoutConstraint!
    
    @IBOutlet var notificationShowingConstraint: NSLayoutConstraint!
    @IBOutlet var notificationHiddenConstraint: NSLayoutConstraint!
    @IBOutlet var notificationContainer: UIView!
    
    @IBOutlet var topBar: UIView!
    @IBOutlet var topBarDivider: UIView!
    
    @IBOutlet var topLeftButton: UIButton!
    @IBOutlet var topRightButton: UIButton!
    
    @IBOutlet var sublabelView: UIView!
    @IBOutlet var numActiveLabel: UILabel!
    
    var chatListController: ChatListController!
    var chatViewController: ChatViewController!
    var chatAlertController: ChatAlertController!
    
    var confirmLeaveAlertView = UIAlertView()
    var chatAdded = false
    
    override func viewDidLoad() {
        topBar.backgroundColor = ColorConstants.chatNavBackground
        topBarDivider.backgroundColor = ColorConstants.chatNavBorder
        numActiveLabel.textColor = ColorConstants.textSecondary
        
        chatListController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("ChatListController") as! ChatListController
        chatListController.delegate = self
        addChildViewController(chatListController)
        listContainer.addSubview(chatListController.view)
        chatListController.view.autoPinEdgesToSuperviewEdges()
        
        chatViewController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
        chatViewController.delegate = self
        
        confirmLeaveAlertView = UIAlertView(title: "Are you sure?", message: "Leaving the chat will mean you lose your nickname", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Leave")
        
        chatAlertController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("ChatAlertController") as! ChatAlertController
        chatAlertController.delegate = self
        addChildViewController(chatAlertController)
        notificationContainer.addSubview(chatAlertController.view)
        chatAlertController.view.autoPinEdgesToSuperviewEdges()
        
        Utilities.appDelegate().setUserOnboarded()
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
        
        PFCloud.callFunctionInBackground("joinNextAvailableChatRoom", withParameters: ["userId": User.theUser.objectId, "maxOccupancy": 5, "pubkey": EnvironmentConstants.pubNubPublishKey, "subkey": EnvironmentConstants.pubNubSubscribeKey]) { (object: AnyObject?, error: NSError?) -> Void in
            let alias = Alias.createOrUpdateAliasFromParseObject(object as! PFObject, isTemporary: false)
            chatRoom = ChatRoom.createWithMyAlias(alias)
            Utilities.appDelegate().saveContext()
            Utilities.appDelegate().subscribeToPubNubChannel(chatRoom.objectId)
            Utilities.appDelegate().subscribeToPubNubPushChannel(chatRoom.objectId)
            Answers.logCustomEventWithName("Joined Chat", customAttributes: nil)
            self.chatListController.reloadRooms()
            if (animationComplete) {
                self.showChatRoom(chatRoom)
            }
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
        
        chatAlertController.chatRoom = chatRoom
        chatAlertController.label.text = "New Mess in ChatRoom \(chatRoom.objectId)"
        
        UIView.animateWithDuration(0.333) { 
            self.notificationHiddenConstraint.priority = 200
            self.notificationShowingConstraint.priority = 900
            self.view.layoutIfNeeded()
        }
    }
    
    func hideNewMessageAlert() {
        UIView.animateWithDuration(0.333) {
            self.notificationHiddenConstraint.priority = 900
            self.notificationShowingConstraint.priority = 200
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: Button Actions
    
    @IBAction func topRightButtonTap() {
        if (isShowingList()) {
           joinNextAndAnimate()
        }
        else {
            self.performSegueWithIdentifier("popoverMenuSegue", sender: self)
        }
    }
    
    @IBAction func topLeftButtonTap() {
        if (isShowingList()) {
        }
        else {
            showList()
        }
    }
    
    // MARK: ChatViewControllerDelegate
    
    func subscribe(chatRoom:ChatRoom) {
        Utilities.appDelegate().subscribeToPubNubChannel(chatRoom.objectId)
        Utilities.appDelegate().subscribeToPubNubPushChannel(chatRoom.objectId)
        chatRoom.delegate = self
    }
    
    func showList() {
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
            self.topLeftButton.imageView?.image = UIImage(named: "Hamburger")
            self.topRightButton.imageView?.image = UIImage(named: "NewChat")
            self.view.layoutIfNeeded()
        }) { (error: Bool) in
            self.chatListController.reloadRooms()
        }
    }
    
    func tryLeaveChatRoom(alias: Alias) {
        confirmLeaveAlertView.show()
    }
    
    func leaveChatRoom(alias: Alias) {
        
        delegate.showLoadingViewWithText("Leaving Chat...")
        
        PFCloud.callFunctionInBackground("leaveChatRoom", withParameters: ["aliasId": alias.objectId!, "pubkey": EnvironmentConstants.pubNubPublishKey, "subkey": EnvironmentConstants.pubNubSubscribeKey]) { (object: AnyObject?, error: NSError?) -> Void in
            
            if (error != nil) {
                self.delegate.hideLoadingView()
                return
            }
            
            self.forceLeaveChatRoom(alias)
        }
    }

    
    func forceLeaveChatRoom(alias: Alias) {
        if let chatRoom = ChatRoom.fetchById(alias.chatRoomId) {
            Answers.logCustomEventWithName("Left Chat", customAttributes: ["chatRoomId": chatRoom.objectId, "lengthOfStay":chatRoom.myAlias.joinedAt.timeIntervalSinceNow * -1 * 1000])
            Utilities.appDelegate().managedObjectContext.deleteObject(chatRoom)
            Utilities.appDelegate().saveContext()
        }
        Utilities.appDelegate().unsubscribeFromPubNubChannel(alias.chatRoomId)
        Utilities.appDelegate().unsubscribeFromPubNubPushChannel(alias.chatRoomId)
        delegate.hideLoadingView()
        showList()
    }
    
    func didUpdateActiveAliases(aliases:NSSet) {
        if (aliases.count == 0) {
            numActiveLabel.text = "Waiting for others..."
        }
        else {
            numActiveLabel.text = "\(aliases.count) members"
        }
    }
    
    func isCurrentChatRoom(chatRoom: ChatRoom) -> Bool {
        if (chatRoom.objectId == currentAlias()?.chatRoomId &&
            !isShowingList()) {
            return true
        }
        return false
    }
    
    // MARK: ChatListControllerDelegate
    
    func showChatRoom(chatRoom: ChatRoom) {
        chatRoom.delegate = self
        chatViewController.chatRoom = chatRoom
        
        hideNewMessageAlert()
        
        if (!chatAdded) {
            dispatch_async(dispatch_get_main_queue(), {
                self.addChildViewController(self.chatViewController)
                self.chatContainer.addSubview(self.chatViewController.view)
                self.chatViewController.view.autoPinEdgesToSuperviewEdges()
            });
            chatAdded = true
        }
        
        UIView.animateWithDuration(0.333, animations:{
            self.chatContainerFocusConstraint.priority = 900
            self.listContainerFocusConstraint.priority = 200
            self.sublabelShowingConstraint.priority = 900
            self.sublabelHiddenConstraint.priority = 200
            self.sublabelView.alpha = 1
            self.topLeftButton.imageView?.image = UIImage(named: "BackArrow")
            self.topRightButton.imageView?.image = UIImage(named: "ThreeDots")
            self.view.layoutIfNeeded()
        }) { (error: Bool) in
            self.delegate.hideLoadingView()
            self.chatViewController.scrollToBottom(true)
        }
    }
    
    // MARK: OptionsMenuControllerDelegate
    
    func selectedFeedback() {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.performSegueWithIdentifier("popoverFeedbackSegue", sender: self)
    }
    
    func shouldClose() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func tryLeaveChatRoom() {
        tryLeaveChatRoom(currentAlias())
    }
    
    // MARK: FeedbackViewDelegate
    
    func currentAlias() -> Alias! {
        return chatViewController?.chatRoom?.myAlias
    }
    
    // MARK: UIPopoverPresentationControllerDelegate
    
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
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        
        // Force popover style
        return UIModalPresentationStyle.None
    }
    
    // MARK: UIAlertViewDelegate
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if (buttonIndex == 1 && alertView.isEqual(confirmLeaveAlertView)) {
            leaveChatRoom(currentAlias())
        }
    }
    
    // MARK: ChatRoomDelegate
    
    func didUpdateEvents(chatRoom:ChatRoom) {
        if (!isCurrentChatRoom(chatRoom)) {
            return
        }
        
        chatViewController.reloadTable()
    }
    
    func didAddEvent(chatRoom:ChatRoom, chatEvent:ChatEvent, isMine: Bool) {
        if (!isCurrentChatRoom(chatRoom)) {
            showNewMessageAlert(chatRoom, chatEvent: chatEvent)
            return
        }
        
        didUpdateEvents(chatRoom)
        let lastCellHeight = chatViewController.tableView(chatViewController.tableView, heightForRowAtIndexPath: NSIndexPath(forRow: chatRoom.chatEvents.count - 1, inSection: 0))
        
        if (chatViewController.isNearBottom(lastCellHeight + 55)) {
            chatViewController.scrollToBottom(true)
        }
        else if (!isMine) {
            chatViewController.isUnreadMessages = true
        }
    }
    
    func didUpdateActiveAliases(chatRoom:ChatRoom, aliases:NSSet) {
        if (!isCurrentChatRoom(chatRoom)) {
            return
        }
        
        didUpdateActiveAliases(aliases)
    }
    
    func didReloadEvents(chatRoom:ChatRoom, eventCount:Int, firstLoad: Bool) {
        if (!isCurrentChatRoom(chatRoom)) {
            return
        }
        
        chatViewController.reloadTable()
        if (firstLoad) { chatViewController.scrollToBottom(true) }
        else { chatViewController.scrollToEventIndex(eventCount, animated: false) }
    }
}