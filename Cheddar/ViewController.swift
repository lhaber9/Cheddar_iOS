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

class ViewController: UIViewController, UIScrollViewDelegate, FrontPageViewDelegate, ChatViewControllerDelegate {
    
    @IBOutlet var loadingView: UIView!
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var page0: UIView!
    
    @IBOutlet var leftArrow: UIImageView!
    @IBOutlet var rightArrow: UIImageView!
    
    @IBOutlet var backgroundCheeseLeftConstraint: NSLayoutConstraint!
    @IBOutlet var backgroundCheeseRightConstraint: NSLayoutConstraint!
    var backgroundCheeseInitalLeftConstraint: CGFloat!
    var backgroundCheeseInitalRightConstraint: CGFloat!
    var paralaxScaleFactor: CGFloat = 20
    
    var currentPage: Int = 0
    var pages: [UIView]!
    
    var isAnimatingPages = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
    
        setupPages()
        
        leftArrow.alpha = 0
        
        backgroundCheeseInitalLeftConstraint = backgroundCheeseLeftConstraint.constant
        backgroundCheeseInitalRightConstraint = backgroundCheeseRightConstraint.constant
        
        let loadOverlay = LoadingView.instanceFromNib()
        loadingView.addSubview(loadOverlay)
        loadOverlay.autoPinEdgesToSuperviewEdges()
    }
    
    override func viewDidAppear(animated: Bool) {
        checkInChatRoom()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupPages() {
        let introView = IntroView.instanceFromNib()
        let matchView = MatchView.instanceFromNib()
        let groupView = GroupView.instanceFromNib()
        let alphaWarningView = AlphaWarningView.instanceFromNib()
        
        introView.delegate = self
        matchView.delegate = self
        groupView.delegate = self
        alphaWarningView.delegate = self
        
        pages = [page0]
        addContentsToLastPage(introView)
        addPage(matchView)
        addPage(groupView)
        addPage(alphaWarningView)
    }
    
    func useSmallerViews() -> Bool {
        return Utilities.IS_IPHONE_5() || Utilities.IS_IPHONE_4_OR_LESS()
    }
    
    func displayArrows() {
        UIView.animateWithDuration(0.1) { () -> Void in
            if (self.currentPage == 0) {
                self.leftArrow.alpha = 0
                self.rightArrow.alpha = 1
            }
            else if (self.currentPage == 1 || self.currentPage == 2) {
                self.leftArrow.alpha = 1
                self.rightArrow.alpha = 1
            }
            else if (self.currentPage == 3) {
                self.leftArrow.alpha = 0
                self.rightArrow.alpha = 0
            }
        }
    }
    
    func checkInChatRoom() {
        let chatRoom = ChatRoom.fetchSingleRoom()
        if (chatRoom != nil) {
            self.showChatRoom(chatRoom)
        }
    }
    
    @IBAction func goToNextPage() {
        if (isAnimatingPages) { return }
        scrollToPage(currentPage + 1, animated: true)
    }
    
    @IBAction func goToPrevPage() {
        if (isAnimatingPages) { return }
        scrollToPage(currentPage - 1, animated: true)
    }
    
    func scrollToPage(pageIdx: Int, animated: Bool) {
        isAnimatingPages = true
        if (pageIdx < 0 || pageIdx >= pages.count) {
            return
        }
        
        currentPage = pageIdx
        scrollView.setContentOffset(CGPointMake(scrollView.frame.size.width * CGFloat(currentPage), 0.0), animated:animated)
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
    
    func joinNextAndAnimate() {
        
        var chatRoom: ChatRoom!
        var animationComplete = false
        
        PFCloud.callFunctionInBackground("joinNextAvailableChatRoom", withParameters: ["userId": User.theUser.objectId, "maxOccupancy": 1, "pubkey": EnvironmentConstants.pubNubPublishKey, "subkey": EnvironmentConstants.pubNubSubscribeKey]) { (object: AnyObject?, error: NSError?) -> Void in
            let alias = Alias.createAliasFromParseObject(object as! PFObject, isTemporary: false)
            chatRoom = ChatRoom.createWithMyAlias(alias)
            Utilities.appDelegate().saveContext()
            Utilities.appDelegate().subscribeToPubNubChannel(chatRoom.objectId)
            Utilities.appDelegate().subscribeToPubNubPushChannel(chatRoom.objectId)
            Answers.logCustomEventWithName("Joined Chat", customAttributes: nil)
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
            self.loadingView.alpha = 0
            self.loadingView.hidden = true
        }
    }
    
    func performJoinChatAnimation(callback: () -> Void) {
        UIView.animateWithDuration(0.33) { () -> Void in
            self.loadingView.alpha = 1
            self.loadingView.hidden = false
        }
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(4 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            callback()
        }
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
    
    // ChatViewContollerDelegate
    
    func closeChat() {
        self.scrollToPage(self.currentPage, animated: false)
        isAnimatingPages = false
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    // UIScrollViewDelegate
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        currentPage = Int(scrollView.contentOffset.x / scrollView.frame.size.width);
        displayArrows()
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        isAnimatingPages = false
        currentPage = Int(scrollView.contentOffset.x / scrollView.frame.size.width);
        displayArrows()
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let paralaxOffset = scrollView.contentOffset.x / paralaxScaleFactor;
        
        backgroundCheeseLeftConstraint.constant  = backgroundCheeseInitalLeftConstraint - paralaxOffset
        backgroundCheeseRightConstraint.constant = backgroundCheeseInitalRightConstraint + paralaxOffset
        
        view.layoutIfNeeded()
    }
}

