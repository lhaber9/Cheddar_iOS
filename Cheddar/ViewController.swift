//
//  ViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/1/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import UIKit
import Parse

class ViewController: UIViewController, FrontPageViewControllerDelegate, ChatViewControllerDelegate {

    @IBOutlet var backgroundView: UIView!
    @IBOutlet var shadowBackgroundView: UIView!
    @IBOutlet var spinnerView: UIView!
    @IBOutlet var spinnerImageView: UIImageView!
    @IBOutlet var container0: UIView!
    @IBOutlet var page0: UIView!
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet var scrollViewHeightConstrait: NSLayoutConstraint!
    @IBOutlet var containerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var scrollViewPositionConstrait: NSLayoutConstraint!
    @IBOutlet var backgroundViewHeightConstrait: NSLayoutConstraint!
    @IBOutlet var textHeightConstrait: NSLayoutConstraint!
    
    var scrollViewHeightRaisedConstant: CGFloat = -130
    var scrollViewHeightMiddleConstant: CGFloat = -70
    var scrollViewHeightDefaultConstant: CGFloat = 0
    var scrollViewHeightLoweredConstant: CGFloat = 400
    var scrollViewHeightOffScreenConstant: CGFloat = 550
    
    var backgroundViewHeightDefaultConstant: CGFloat = 300
    var backgroundViewHeightLoweredConstant: CGFloat = 50
    
    var frontPageViewWidthDefault: CGFloat = 320
    var frontPageViewWidthSmall: CGFloat = 240
    
    var containers: [UIView]!
    var pages: [UIView]!
    var currentPage: Int = 0
    
    let kRotationAnimationKey = "cheddar.spinnerrotationanimationkey"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinnerView.alpha = 0
        
        backgroundView.backgroundColor = ColorConstants.colorPrimary
        
        spinnerImageView.image = UIImage(named: "VectorIcon")
        view.setNeedsDisplay()
        
        setShawdowForView(shadowBackgroundView)
        shadowBackgroundView.layer.shadowRadius = 5;
        shadowBackgroundView.layer.shadowOpacity = 0.8;
        shadowBackgroundView.backgroundColor = ColorConstants.solidGray
        
        containers = [container0]
        pages = [page0]
        let introViewController = IntroViewController()
        addViewControllerPageToLastContainer(introViewController)
        
        if (Utilities.IS_IPHONE_6_PLUS()) {
            textHeightConstrait.constant = 145
        }
        else if (Utilities.IS_IPHONE_5()) {
            textHeightConstrait.constant = 45
            backgroundViewHeightDefaultConstant -= 60
        }
        else if (Utilities.IS_IPHONE_4_OR_LESS()) {
            textHeightConstrait.constant = 25
            backgroundViewHeightDefaultConstant -= 110
            scrollViewHeightConstrait.constant -= 35
            containerHeightConstraint.constant -= 35
        }
        
        backgroundViewHeightConstrait = shadowBackgroundView.autoSetDimension(ALDimension.Height, toSize: backgroundViewHeightDefaultConstant)
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
            self.showChatRoom(chatRoom, sendJoinEvent: false)
        }
    }
    
    func goToNext() {
        scrollToPage(currentPage + 1, animated: true)
    }
    
    func scrollToPage(pageIdx: Int, animated: Bool) {
        scrollView.setContentOffset(CGPointMake(scrollView.frame.size.width * CGFloat(pageIdx), 0.0), animated:animated)
        currentPage = pageIdx
    }
    
    func setShawdowForView(view: UIView) {
        view.layer.masksToBounds = false;
        view.layer.shadowOffset = CGSizeMake(0, 0);
        view.layer.shadowRadius = 3;
        view.layer.shadowOpacity = 0.5;
    }
    
    func goToNextPageWithController(viewController: FrontPageViewController) {
        addContainerAndPage()
        addViewControllerPageToLastContainer(viewController)
        goToNext()
    }
    
    func addContainerAndPage() {
        let lastPage = pages.last!
        lastPage.removeConstraint(scrollViewWidthConstraint)
        scrollViewWidthConstraint = nil
        let pageView = UIView()
        scrollView.addSubview(pageView)
        
        pageView.autoMatchDimension(ALDimension.Width, toDimension:ALDimension.Width, ofView: lastPage)
        pageView.autoPinEdge(ALEdge.Top, toEdge: ALEdge.Top, ofView: lastPage)
        pageView.autoPinEdge(ALEdge.Bottom, toEdge: ALEdge.Bottom, ofView: lastPage)
        pageView.autoPinEdge(ALEdge.Left, toEdge: ALEdge.Right, ofView: lastPage)
        
        scrollViewWidthConstraint = NSLayoutConstraint(item: lastPage, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: scrollView, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
        scrollViewWidthConstraint.priority = 900
        
        view.addConstraint(scrollViewWidthConstraint)

        pages.append(pageView)
        
        let lastContainer = containers.last!
        let containerView = UIView()
        pageView.addSubview(containerView)
        
        containerView.autoMatchDimension(ALDimension.Width, toDimension: ALDimension.Width, ofView: lastContainer)
        containerView.autoPinEdge(ALEdge.Top, toEdge: ALEdge.Top,ofView: lastContainer)
        containerView.autoPinEdge(ALEdge.Bottom, toEdge: ALEdge.Bottom, ofView: lastContainer)
        containerView.autoAlignAxisToSuperviewAxis(ALAxis.Vertical)
        
        containers.append(containerView)
    }
    
    func addViewControllerPageToLastContainer(viewController: FrontPageViewController) {
        
        viewController.delegate = self
        addChildViewController(viewController)
        let view = viewController.view
        
        let containerView = containers.last!
        containerView.addSubview(view)
        
        view.autoPinEdgesToSuperviewEdges()
        
        setShawdowForView(view)
    }
    
    // FrontPageViewControllerDelegate
    
    func joinChat(isSingle: Bool) {
        if (isSingle) {
            UIAlertView(title: "Oops", message: "One on One Chat Not Available Yet", delegate: self, cancelButtonTitle: "ok").show()
        }
        else {
            let chatRoom = ChatRoom.fetchSingleRoom()
            if (chatRoom == nil) {
                joinNextAndAnimate()
            }
            else {
                self.showChatRoom(chatRoom, sendJoinEvent: false)
            }
        }
    }
    
    func joinNextAndAnimate() {
        
        var chatRoom: ChatRoom!
        var animationComplete = false
        
        PFCloud.callFunctionInBackground("joinNextAvailableChatRoom", withParameters: ["userId": User.theUser.objectId, "maxOccupancy": 1]) { (object: AnyObject?, error: NSError?) -> Void in
            let alias = Alias.createAliasFromParseObject(object as! PFObject)
            chatRoom = ChatRoom.createWithMyAlias(alias)
            (UIApplication.sharedApplication().delegate as! AppDelegate).saveContext()
            (UIApplication.sharedApplication().delegate as! AppDelegate).subscribeToPubNubChannel(chatRoom.objectId, alias: alias)
            if (animationComplete) {
                self.showChatRoom(chatRoom, sendJoinEvent: true)
            }
        }
        
        performJoinChatAnimation { () -> Void in
            animationComplete = true
            if (chatRoom != nil) {
                self.showChatRoom(chatRoom, sendJoinEvent: true)
            }
        }
    }
    
    func showChatRoom(chatRoom: ChatRoom, sendJoinEvent: Bool) {
        let chatViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
        chatViewController.delegate = self
        chatViewController.chatRoomId = chatRoom.objectId
        chatViewController.myAlias = chatRoom.myAlias
        NSLog("Joining ChatRoom: " + chatRoom.objectId)
        self.presentViewController(chatViewController, animated: true) { () -> Void in
            self.scrollViewToDefault()
            self.scrollBackgroundViewToDefault()
            self.spinnerView.alpha = 0
            self.spinnerView.layer.removeAllAnimations()
            if (sendJoinEvent) {
                (UIApplication.sharedApplication().delegate as! AppDelegate).joinPubNubChannel(chatRoom.objectId, alias: chatRoom.myAlias)
            }
        }
    }
    
    func animateScrollViewToRaised() {
        UIView.animateWithDuration(0.333) { () -> Void in
            self.scrollViewPositionConstrait.constant = self.scrollViewHeightRaisedConstant;
            self.view.layoutIfNeeded()
        }
    }
    
    func animateScrollViewToDefault() {
        UIView.animateWithDuration(0.333) { () -> Void in
            self.scrollViewToDefault()
        }
    }
    
    func scrollViewToDefault() {
        self.scrollViewPositionConstrait.constant = self.scrollViewHeightDefaultConstant;
        self.view.layoutIfNeeded()
    }
    
    func scrollBackgroundViewToDefault() {
        self.backgroundViewHeightConstrait.constant = self.backgroundViewHeightDefaultConstant;
        self.view.layoutIfNeeded()
    }
    
    func animateScrollViewToLowered() {
        UIView.animateWithDuration(0.333) { () -> Void in
            self.scrollViewPositionConstrait.constant = self.scrollViewHeightLoweredConstant;
            self.view.layoutIfNeeded()
        }
    }
    
    func animateScrollViewToOffScreen() {
        UIView.animateWithDuration(0.333) { () -> Void in
            self.scrollViewPositionConstrait.constant = self.scrollViewHeightOffScreenConstant;
            self.view.layoutIfNeeded()
        }
    }
    
    func startSpinner() {
        self.spinnerView.alpha = 1
        
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = Float(M_PI * 2.0)
        rotationAnimation.duration = 1
        rotationAnimation.repeatCount = Float.infinity
        
        spinnerView.layer.addAnimation(rotationAnimation, forKey: kRotationAnimationKey)
    }
    
    func performJoinChatAnimation(callback: () -> Void) {
        UIView.animateWithDuration(0.333, animations: { () -> Void in
            self.scrollViewPositionConstrait.constant = self.scrollViewHeightMiddleConstant
            self.view.layoutIfNeeded()
            self.startSpinner()
            }) { (success: Bool) -> Void in
                UIView.animateWithDuration(0.666, animations: { () -> Void in
                    self.scrollViewPositionConstrait.constant = self.scrollViewHeightOffScreenConstant
                    self.backgroundViewHeightConstrait.constant = self.backgroundViewHeightLoweredConstant
                    self.view.layoutIfNeeded()
                    }) { (success: Bool) -> Void in
                        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC)))
                        dispatch_after(delayTime, dispatch_get_main_queue()) {
                            callback()
                        }
                }
        }
    }
    
    // ChatViewContollerDelegate
    
    func leaveChat(alias:Alias) {
        PFCloud.callFunctionInBackground("leaveChatRoom", withParameters: ["aliasId": alias.objectId!]) { (object: AnyObject?, error: NSError?) -> Void in
            if let chatRoom = ChatRoom.fetchSingleRoom() {
                (UIApplication.sharedApplication().delegate as! AppDelegate).leavePubNubChannel(chatRoom.objectId, alias: alias)
                (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext.deleteObject(chatRoom)
                (UIApplication.sharedApplication().delegate as! AppDelegate).saveContext()
            }
            (UIApplication.sharedApplication().delegate as! AppDelegate).unsubscribeFromPubNubChannel(alias.chatRoomId, alias: alias)
            self.scrollToPage(self.currentPage, animated: false)
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
    }
}

