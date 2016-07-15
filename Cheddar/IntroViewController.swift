//
//  IntroViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/29/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Parse

protocol IntroDelegate: class {
    func didCompleteSignup(user: PFUser)
    func didCompleteLogin()
    func scrollViewDidScroll(scrollView: UIScrollView)
    func showLoadingViewWithText(text: String)
    func hideLoadingView()
    func showOverlay()
    func hideOverlay()
}

class IntroViewController: FullPageScrollView, LoginSignupDelegate {
    
    weak var delegate: IntroDelegate!
    
    var loginSignupViewController: LoginSignupViewController!
    
    @IBOutlet var leftArrow: UIImageView!
    @IBOutlet var rightArrow: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        leftArrow.alpha = 0
        
        setupOnboardingPages()
        
        loginSignupViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LoginSignupViewController") as! LoginSignupViewController
        addChildViewController(loginSignupViewController)
        loginSignupViewController.delegate = self
        
        addPage(loginSignupViewController.view)
    }
    
    func setupOnboardingPages() {
        let introView = IntroView.instanceFromNib()
        let matchView = MatchView.instanceFromNib()
        let groupView = GroupView.instanceFromNib()
        
        introView.delegate = self
        matchView.delegate = self
        groupView.delegate = self
        
        addPage(introView)
        addPage(matchView)
        addPage(groupView)
    }
    
    func didScrollToPage(page: Int) {
        UIView.animateWithDuration(0.1) { () -> Void in
            if (page == 0) {
                self.leftArrow.alpha = 0
                self.rightArrow.alpha = 1
            }
            else if (page == 1 || page == 2) {
                self.leftArrow.alpha = 1
                self.rightArrow.alpha = 1
            }
            else {
                self.leftArrow.alpha = 0
                self.rightArrow.alpha = 0
            }
        }
        
        if (page != pages.count - 1) {
            loginSignupViewController.deselectTextFields()
        }
    }
    
    // MARK: UIScrollViewDelegate
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        super.scrollViewDidEndDecelerating(scrollView);
        didScrollToPage(self.currentPageIndex)
//        updateIfLoginPage()
    }
    
    override func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        super.scrollViewDidEndScrollingAnimation(scrollView);
        didScrollToPage(self.currentPageIndex)
//        updateIfLoginPage()
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        delegate.scrollViewDidScroll(scrollView)
    }
    
    // MARK: LoginSignupDelegate
    
    func didCompleteLogin() {
        delegate.didCompleteLogin()
        scrollView.scrollEnabled = false
        Utilities.appDelegate().setDeviceOnboarded()
    }
    
    func didCompleteSignup(user: PFUser) {
        delegate.didCompleteSignup(user)
        scrollView.scrollEnabled = false
        Utilities.appDelegate().setDeviceOnboarded()
    }
    
    func showLoadingViewWithText(text: String) {
        delegate.showLoadingViewWithText(text)
    }
    
    func hideLoadingView() {
        delegate.hideLoadingView()
    }
    
    func showOverlay() {
        delegate.showOverlay()
    }
    
    func hideOverlay() {
        delegate.hideOverlay()
    }
}
