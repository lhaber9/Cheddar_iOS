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
    @IBOutlet var container0: UIView!
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet var scrollViewHeightConstrait: NSLayoutConstraint!
    
    var scrollViewHeightRaisedConstant: CGFloat = -130
    var scrollViewHeightLoweredConstant: CGFloat = 180
    
    var containers: [UIView]!
    var currentPage: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundView.backgroundColor = ColorConstants.colorPrimary
        
        setShawdowForView(shadowBackgroundView)
        shadowBackgroundView.layer.shadowRadius = 5;
        shadowBackgroundView.layer.shadowOpacity = 0.8;
        shadowBackgroundView.backgroundColor = ColorConstants.solidGray
        
        containers = [container0]
        let introViewController = IntroViewController()
        addViewControllerPageToLastContainer(introViewController)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            let chatRooms = ChatRoom.fetchAll()
            if (chatRooms.count == 0) {
                PFCloud.callFunctionInBackground("joinNextAvailableChatRoom", withParameters: ["userId": User.theUser.objectId, "maxOccupancy": 1]) { (object: AnyObject?, error: NSError?) -> Void in
                    let alias = Alias.createAliasFromParseObject(object as! PFObject)
                    ChatRoom.createWithMyAlias(alias)
                    (UIApplication.sharedApplication().delegate as! AppDelegate).saveContext()
                    self.showChatWithAlias(alias)
                }
            }
            else {
                let chatRoom = chatRooms[0]
                self.showChatWithAlias(chatRoom.myAlias)
            }
        }
    }
    
    func showChatWithAlias(alias: Alias) {
        let chatViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ChatViewController") as! ChatViewController
        chatViewController.delegate = self
        chatViewController.channelId = alias.chatRoomId
        chatViewController.alias = alias
        self.presentViewController(chatViewController, animated: true, completion: nil)
    }
    
    func raiseScrollView() {
        UIView.animateWithDuration(0.333) { () -> Void in
            self.scrollViewHeightConstrait.constant = self.scrollViewHeightRaisedConstant;
            self.view.layoutIfNeeded()
        }
    }
    
    func lowerScrollView() {
        UIView.animateWithDuration(0.333) { () -> Void in
            self.scrollViewHeightConstrait.constant = 0;
            self.view.layoutIfNeeded()
        }
    }
    
    // ChatViewContollerDelegate
    
    func closeChat() {
        self.scrollToPage(self.currentPage, animated: false);
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}

