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

class ViewController: UIViewController, UIScrollViewDelegate, FrontPageViewDelegate, ChatDelegate {
    
    @IBOutlet var loadingView: UIView!
    var loadOverlay: LoadingView!
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var scrollViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet var page0: UIView!
    
    @IBOutlet var chatContainer: UIView!
    
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
        
        loadOverlay = LoadingView.instanceFromNib()
        loadingView.addSubview(loadOverlay)
        loadOverlay.autoPinEdgesToSuperviewEdges()
        
        checkInChatRoom()
    }
    
    override func viewDidAppear(animated: Bool) {
        
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
        let chatRoom = ChatRoom.fetchAll()
        if (chatRoom.count > 0) {
            self.showChat()
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
    
    // FrontPageViewDelegate
    
    func showChat() {
        let chatController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("ChatController") as! ChatController

        chatController.delegate = self
        addChildViewController(chatController)
        chatContainer.addSubview(chatController.view)
        chatController.view.autoPinEdgesToSuperviewEdges()
        
        chatContainer.hidden = false
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
    
    // MARK: ChatDelegate
    
    func showLoadingViewWithText(text: String) {
        loadOverlay.loadingTextLabel.text = text
        UIView.animateWithDuration(0.333) { () -> Void in
            self.loadingView.alpha = 1
            self.loadingView.hidden = false
        }
    }
    
    func hideLoadingView() {
        UIView.animateWithDuration(0.333) { () -> Void in
            self.loadingView.alpha = 0
            self.loadingView.hidden = true
        }
    }
}

