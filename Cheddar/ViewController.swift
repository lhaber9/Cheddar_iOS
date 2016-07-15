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

class ViewController: UIViewController, UIScrollViewDelegate, IntroDelegate, ChatDelegate {
    
    @IBOutlet var loadingView: UIView!
    var loadOverlay: LoadingView!
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var backgroundCheeseLeftConstraint: NSLayoutConstraint!
    @IBOutlet var backgroundCheeseRightConstraint: NSLayoutConstraint!
    var backgroundCheeseInitalLeftConstraint: CGFloat!
    var backgroundCheeseInitalRightConstraint: CGFloat!
    var paralaxScaleFactor: CGFloat = 20
    
    @IBOutlet var overlayContainer: UIView!
    @IBOutlet var overlayContentsContainer: UIView!
    var overlayContentsController: UIViewController!
    
    @IBOutlet var chatContainer: UIView!
    @IBOutlet var introContainer: UIView!
    var chatController: ChatController!
    var introController: IntroViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundCheeseInitalLeftConstraint = backgroundCheeseLeftConstraint.constant
        backgroundCheeseInitalRightConstraint = backgroundCheeseRightConstraint.constant
        
        loadOverlay = LoadingView.instanceFromNib()
        loadingView.addSubview(loadOverlay)
        loadOverlay.autoPinEdgesToSuperviewEdges()
        
        introController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("IntroViewController") as! IntroViewController
        
        introController.delegate = self
        addChildViewController(introController)
        introContainer.addSubview(introController.view)
        introController.view.autoPinEdgesToSuperviewEdges()

        view.layoutIfNeeded()
        
        if (CheddarRequest.currentUser() != nil) {
            didCompleteLogin()
        }
        else {
            if (Utilities.appDelegate().deviceDidOnboard()) {
                goToLogin()
            }
        }

    }
    
    override func viewDidAppear(animated: Bool) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldAutorotate() -> Bool {
        return chatController != nil
    }
    
    func useSmallerViews() -> Bool {
        return Utilities.IS_IPHONE_4_OR_LESS()
    }
    
    func showVerifyEmailScreen() {
        performSegueWithIdentifier("showVerifyEmail", sender: self)
    }
    
    func didCompleteLogin() {
        goToLogin()
        self.showChat()
        CheddarRequest.currentUserIsVerified({ (isVerified) in
            self.hideLoadingView()
            if (!isVerified) {
                self.showVerifyEmailScreen()
            }
            }, errorCallback: { (error) in
                self.hideLoadingView()
        })
    }
    
    func didCompleteSignup(user: PFUser) {
        showVerifyEmailScreen()
    }
    
    func goToLogin() {
        introController.goToLastPage()
    }

    // MARK: FullPageScrollDelegate
    
    func changeBackgroundColor(color: UIColor){
        backgroundView.backgroundColor = color
        view.layoutIfNeeded()
    }
    
    func showChat() {
        if (CheddarRequest.currentUser() == nil) {
            return
        }
        
        chatController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewControllerWithIdentifier("ChatController") as! ChatController
        
        chatController.delegate = self
        addChildViewController(chatController)
        chatContainer.addSubview(chatController.view)
        chatController.view.autoPinEdgesToSuperviewEdges()
        
        chatContainer.hidden = false
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
    
    func showOverlay() {
        UIView.animateWithDuration(0.33, animations: {
            self.overlayContainer.hidden = false
            self.overlayContainer.alpha = 1
            self.view.layoutIfNeeded()
        })
    }
    
    func hideOverlay() {
        UIView.animateWithDuration(0.33, animations: {
            self.overlayContainer.alpha = 0
            self.view.layoutIfNeeded()
        }) { (completed: Bool) in
            self.overlayContainer.hidden = true
        }
    }
    
    func showOverlayContents(viewController: UIViewController) {
        addChildViewController(viewController)
        overlayContentsContainer.addSubview(viewController.view)
        viewController.view.autoPinEdgesToSuperviewEdges()
        overlayContentsController = viewController
        self.view.layoutIfNeeded()
        
        UIView.animateWithDuration(0.33, animations: {
            self.overlayContentsContainer.hidden = false
            self.overlayContentsContainer.alpha = 1
            self.view.layoutIfNeeded()
        })
    }
    
    func hideOverlayContents() {
        UIView.animateWithDuration(0.33, animations: {
            self.overlayContentsContainer.alpha = 0
            self.view.layoutIfNeeded()
        }) { (completed: Bool) in
            self.overlayContentsContainer.hidden = true
            self.overlayContentsController?.view.removeFromSuperview()
            self.overlayContentsController?.removeFromParentViewController()
            self.overlayContentsController = nil
        }
    }
    
    func removeChat() {
        chatController.view.removeFromSuperview()
        chatController.removeFromParentViewController()
        chatController = nil
        
        chatContainer.hidden = true
    }
}

