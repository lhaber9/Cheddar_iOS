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

class ChatController: UIViewController, UIPopoverPresentationControllerDelegate, OptionsMenuControllerDelegate, FeedbackViewDelegate, ChatListControllerDelegate, ChatViewControllerDelegate, UIAlertViewDelegate {
    
    @IBOutlet var listContainer: UIView!
    @IBOutlet var chatContainer: UIView!
    
    @IBOutlet var listContainerFocusConstraint: NSLayoutConstraint!
    @IBOutlet var chatContainerFocusConstraint: NSLayoutConstraint!
    
    @IBOutlet var sublabelShowingConstraint: NSLayoutConstraint!
    @IBOutlet var sublabelHiddenConstraint: NSLayoutConstraint!
    
    @IBOutlet var topBar: UIView!
    @IBOutlet var topBarDivider: UIView!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var dotsButton: UIButton!
    @IBOutlet var sublabelView: UIView!
    @IBOutlet var numActiveLabel: UILabel!
    
    var chatListController: ChatListController!
    var chatViewController: ChatViewController!
    
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
            let alias = Alias.createAliasFromParseObject(object as! PFObject, isTemporary: false)
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
//        UIView.animateWithDuration(0.333) { () -> Void in
//            self.loadingView.alpha = 1
//            self.loadingView.hidden = false
//        }
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(4 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            callback()
        }
    }
    
//    func clearChatView() {
//        if (chatViewController != nil) {
//            chatViewController.view.removeFromSuperview()
//            chatViewController.removeFromParentViewController()
//            chatViewController.chatRoomController = nil
//            chatViewController = nil
//        }
//    }
    
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
    
    func showList() {
        UIView.animateWithDuration(0.333) { 
            self.chatContainerFocusConstraint.priority = 200
            self.listContainerFocusConstraint.priority = 900
            self.sublabelShowingConstraint.priority = 200
            self.sublabelHiddenConstraint.priority = 900
            self.sublabelView.alpha = 0
            self.view.layoutIfNeeded()
            
            if let selectedRow = self.chatListController.tableView.indexPathForSelectedRow {
                self.chatListController.tableView.deselectRowAtIndexPath(selectedRow, animated: true)
            }
            
            self.chatViewController.deselectTextView()
        }
    }
    
    func leaveChatRoom(alias: Alias) {
        //        UIView.animateWithDuration(0.33) { () -> Void in
        //            self.loadingView.alpha = 1
        //        }
        
        PFCloud.callFunctionInBackground("leaveChatRoom", withParameters: ["aliasId": alias.objectId!, "pubkey": EnvironmentConstants.pubNubPublishKey, "subkey": EnvironmentConstants.pubNubSubscribeKey]) { (object: AnyObject?, error: NSError?) -> Void in
            
            if (error != nil) {
                //                UIView.animateWithDuration(0.333) { () -> Void in
                //                    self.loadingView.alpha = 0
                //                }
                return
            }
            
            self.leaveChatRoomCallback(alias)
        }
    }
    
    func leaveChatRoomCallback(alias: Alias) {
        if let chatRoom = ChatRoom.fetchById(alias.chatRoomId) {
            Answers.logCustomEventWithName("Left Chat", customAttributes: ["chatRoomId": chatRoom.objectId, "lengthOfStay":chatRoom.myAlias.joinedAt.timeIntervalSinceNow * -1 * 1000])
            Utilities.appDelegate().managedObjectContext.deleteObject(chatRoom)
            Utilities.appDelegate().saveContext()
        }
        Utilities.appDelegate().unsubscribeFromPubNubChannel(alias.chatRoomId)
        Utilities.appDelegate().unsubscribeFromPubNubPushChannel(alias.chatRoomId)
        showList()
    }
    
    func didUpdateActiveAliases(aliases:[Alias]) {
        if (aliases.count == 0) {
            numActiveLabel.text = "Waiting for others..."
        }
        else {
            numActiveLabel.text = "\(aliases.count) members"
        }
    }
    
    // MARK: ChatListControllerDelegate
    
    func showChatRoom(chatRoom: ChatRoom) {
        chatViewController?.chatRoom?.delegate = nil
        chatViewController.chatRoom = chatRoom
        
        if (!chatAdded) {
            dispatch_async(dispatch_get_main_queue(), {
                self.addChildViewController(self.chatViewController)
                self.chatContainer.addSubview(self.chatViewController.view)
                self.chatViewController.view.autoPinEdgesToSuperviewEdges()
            });
            chatAdded = true
        }
        
        UIView.animateWithDuration(0.333) {
            self.chatContainerFocusConstraint.priority = 900
            self.listContainerFocusConstraint.priority = 200
            self.sublabelShowingConstraint.priority = 900
            self.sublabelHiddenConstraint.priority = 200
            self.sublabelView.alpha = 1
            self.view.layoutIfNeeded()
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
    
    // MARK: FeedbackViewDelegate
    
    func currentAlias() -> Alias {
        return chatViewController.chatRoom.myAlias
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
}