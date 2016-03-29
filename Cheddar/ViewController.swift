//
//  ViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/1/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import UIKit
import Parse
import Crashlytics

class ViewController: UIViewController, FrontPageViewDelegate, ChatViewControllerDelegate {

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var page0: UIView!
    
    var currentPage: Int = 0
    var pages: [UIView]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pages = [page0]
        addContentsToLastPage(IntroView.instanceFromNib())
        
        addPage(MatchView.instanceFromNib())
        addPage(GroupView.instanceFromNib())
        addPage(AlphaWarningView.instanceFromNib())
    }
    
    override func viewDidAppear(animated: Bool) {
        checkInChatRoom()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func useSmallerViews() -> Bool {
        return Utilities.IS_IPHONE_5() || Utilities.IS_IPHONE_4_OR_LESS()
    }
    
    func checkInChatRoom() {
        let chatRoom = ChatRoom.fetchSingleRoom()
        if (chatRoom != nil) {
            self.showChatRoom(chatRoom)
        }
    }
    
    func goToNext() {
        scrollToPage(currentPage + 1, animated: true)
    }
    
    func scrollToPage(pageIdx: Int, animated: Bool) {
        scrollView.setContentOffset(CGPointMake(scrollView.frame.size.width * CGFloat(pageIdx), 0.0), animated:animated)
        currentPage = pageIdx
    }
    
    func addPage(pageContents: UIView) {
        let lastPage = pages.last!
        scrollView.removeConstraint(scrollViewWidthConstraint)
        scrollViewWidthConstraint = nil
        let pageView = UIView()
        scrollView.addSubview(pageView)
        
        pageView.autoMatchDimension(ALDimension.Width, toDimension:ALDimension.Width, ofView: lastPage)
        pageView.autoPinEdge(ALEdge.Top, toEdge: ALEdge.Top, ofView: lastPage)
        pageView.autoPinEdge(ALEdge.Bottom, toEdge: ALEdge.Bottom, ofView: lastPage)
        pageView.autoPinEdge(ALEdge.Left, toEdge: ALEdge.Right, ofView: lastPage)
        
        scrollViewWidthConstraint = NSLayoutConstraint(item: pageView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: scrollView, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
        scrollViewWidthConstraint.priority = 900
        
        scrollView.addConstraint(scrollViewWidthConstraint)
        
        pageView.addSubview(pageContents)
        pageContents.autoPinEdgesToSuperviewEdges()
        
        pages.append(pageView)
    }
    
    func addContentsToLastPage(pageContents: UIView) {
        let lastPage = pages.last!
        lastPage.addSubview(pageContents)
        pageContents.autoPinEdgesToSuperviewEdges()
    }

    // FrontPageViewDelegate
    
    func joinChat(inOneOnOne: Bool) {
        if (inOneOnOne) {
            Answers.logCustomEventWithName("Selected On on One Chat", customAttributes: nil)
            UIAlertView(title: "Oops", message: "One on One Chat Not Available Yet", delegate: self, cancelButtonTitle: "ok").show()
        }
        else {
            let chatRoom = ChatRoom.fetchSingleRoom()
            if (chatRoom == nil) {
                joinNextAndAnimate()
            }
            else {
                self.showChatRoom(chatRoom)
            }
        }
    }
    
    func goToNextPage() {
        
    }
    
    func goToPrevPage() {
        
    }
    
    func joinNextAndAnimate() {
        
        var chatRoom: ChatRoom!
        var animationComplete = false
        
        PFCloud.callFunctionInBackground("joinNextAvailableChatRoom", withParameters: ["userId": User.theUser.objectId, "maxOccupancy": 1, "pubkey": EnvironmentConstants.pubNubPublishKey, "subkey": EnvironmentConstants.pubNubSubscribeKey]) { (object: AnyObject?, error: NSError?) -> Void in
            let alias = Alias.createAliasFromParseObject(object as! PFObject, isTemporary: false)
            chatRoom = ChatRoom.createWithMyAlias(alias)
            Utilities.appDelegate().saveContext()
            Utilities.appDelegate().subscribeToPubNubChannel(chatRoom.objectId)
            Utilities.appDelegate().subscribeToPubNubPushChannel(chatRoom.objectId)
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
    
    func showChatRoom(chatRoom: ChatRoom) {
        let chatViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
        chatViewController.delegate = self
        chatViewController.chatRoomController = ChatRoomController.newControllerWithChatRoom(chatRoom)
        NSLog("Joining ChatRoom: " + chatRoom.objectId)
        self.presentViewController(chatViewController, animated: true) { () -> Void in
        }
    }
    
    func performJoinChatAnimation(callback: () -> Void) {
    }
    
    // ChatViewContollerDelegate
    
    func closeChat() {
        self.scrollToPage(self.currentPage, animated: false)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

