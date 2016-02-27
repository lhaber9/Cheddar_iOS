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
    @IBOutlet var container0: UIView!
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet var scrollViewHeightConstrait: NSLayoutConstraint!
    @IBOutlet var backgroundViewHeightConstrait: NSLayoutConstraint!
    @IBOutlet var textHeightConstrait: NSLayoutConstraint!
    
    var scrollViewHeightRaisedConstant: CGFloat = -130
    var scrollViewHeightMiddleConstant: CGFloat = -70
    var scrollViewHeightDefaultConstant: CGFloat = 0
    var scrollViewHeightLoweredConstant: CGFloat = 400
    var scrollViewHeightOffScreenConstant: CGFloat = 550
    
    var backgroundViewHeightDefaultConstant: CGFloat = 300
    var backgroundViewHeightLoweredConstant: CGFloat = 50
    
    var containers: [UIView]!
    var currentPage: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        spinnerView.alpha = 0
        
        backgroundView.backgroundColor = ColorConstants.colorPrimary
        
        setShawdowForView(shadowBackgroundView)
        shadowBackgroundView.layer.shadowRadius = 5;
        shadowBackgroundView.layer.shadowOpacity = 0.8;
        shadowBackgroundView.backgroundColor = ColorConstants.solidGray
        
        containers = [container0]
        let introViewController = IntroViewController()
        addViewControllerPageToLastContainer(introViewController)
        
        
        if (Utilities.IS_IPHONE_6_PLUS()) {
            textHeightConstrait.constant = 135
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        checkInChatRoom()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
        addContainer()
        addViewControllerPageToLastContainer(viewController)
        goToNext()
    }
    
    func addContainer() {
        let lastContainer = containers.last!
        lastContainer.removeConstraint(scrollViewWidthConstraint)
        scrollViewWidthConstraint = nil
        let containerView = UIView()
        scrollView.addSubview(containerView)
        
        containerView.autoMatchDimension(ALDimension.Width, toDimension:ALDimension.Width, ofView: lastContainer)
        containerView.autoPinEdge(ALEdge.Top, toEdge: ALEdge.Top, ofView: lastContainer)
        containerView.autoPinEdge(ALEdge.Bottom, toEdge: ALEdge.Bottom, ofView: lastContainer)
        containerView.autoPinEdge(ALEdge.Left, toEdge: ALEdge.Right, ofView: lastContainer)
        
        scrollViewWidthConstraint = NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: scrollView, attribute: NSLayoutAttribute.Trailing, multiplier: 1, constant: 0)
        scrollViewWidthConstraint.priority = 900
        
        view.addConstraint(scrollViewWidthConstraint)

        containers.append(containerView)
    }
    
    func addViewControllerPageToLastContainer(viewController: FrontPageViewController) {
        
        viewController.delegate = self
        addChildViewController(viewController)
        let view = viewController.view
        
        let containerView = containers.last!
        containerView.addSubview(view)
        
        view.autoPinEdgeToSuperviewEdge(ALEdge.Bottom)
        view.autoPinEdgeToSuperviewEdge(ALEdge.Top)
        view.autoSetDimension(ALDimension.Width, toSize: 320)
        view.autoAlignAxisToSuperviewAxis(ALAxis.Vertical)
        
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
            if (sendJoinEvent) {
                (UIApplication.sharedApplication().delegate as! AppDelegate).joinPubNubChannel(chatRoom.objectId, alias: chatRoom.myAlias)
            }
        }
    }
    
    func animateScrollViewToRaised() {
        UIView.animateWithDuration(0.333) { () -> Void in
            self.scrollViewHeightConstrait.constant = self.scrollViewHeightRaisedConstant;
            self.view.layoutIfNeeded()
        }
    }
    
    func animateScrollViewToDefault() {
        UIView.animateWithDuration(0.333) { () -> Void in
            self.scrollViewToDefault()
        }
    }
    
    func scrollViewToDefault() {
        self.scrollViewHeightConstrait.constant = self.scrollViewHeightDefaultConstant;
        self.view.layoutIfNeeded()
    }
    
    func scrollBackgroundViewToDefault() {
        self.backgroundViewHeightConstrait.constant = self.backgroundViewHeightDefaultConstant;
        self.view.layoutIfNeeded()
    }
    
    func animateScrollViewToLowered() {
        UIView.animateWithDuration(0.333) { () -> Void in
            self.scrollViewHeightConstrait.constant = self.scrollViewHeightLoweredConstant;
            self.view.layoutIfNeeded()
        }
    }
    
    func animateScrollViewToOffScreen() {
        UIView.animateWithDuration(0.333) { () -> Void in
            self.scrollViewHeightConstrait.constant = self.scrollViewHeightOffScreenConstant;
            self.view.layoutIfNeeded()
        }
    }
    
    func startSpinner() {
        UIView.animateWithDuration(0.5, animations: { () -> Void in
            self.spinnerView.alpha = 1
            self.spinnerView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI))
            self.view.layoutIfNeeded()
            }) { (success: Bool) -> Void in
                let options : UIViewAnimationOptions = [UIViewAnimationOptions.Repeat, UIViewAnimationOptions.CurveLinear]
                UIView.animateWithDuration(0.25, delay: 0, options: options, animations: { () -> Void in
                        let transform = CGAffineTransformMakeRotation(CGFloat(M_PI * -0.05));
                        self.spinnerView.transform = transform;
                        self.view.layoutIfNeeded()
                    }) { (success: Bool) -> Void in
                }
        }
    }
    
    func performJoinChatAnimation(callback: () -> Void) {
        UIView.animateWithDuration(0.333, animations: { () -> Void in
            self.scrollViewHeightConstrait.constant = self.scrollViewHeightMiddleConstant
            self.view.layoutIfNeeded()
            self.startSpinner()
            }) { (success: Bool) -> Void in
                UIView.animateWithDuration(0.666, animations: { () -> Void in
                    self.scrollViewHeightConstrait.constant = self.scrollViewHeightOffScreenConstant
                    self.backgroundViewHeightConstrait.constant = self.backgroundViewHeightLoweredConstant
                    self.view.layoutIfNeeded()
                    }) { (success: Bool) -> Void in
                        callback()
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

