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

class ViewController: UIViewController, UIScrollViewDelegate, FullPageScrollDelegate, LoginDelegate, ChatDelegate {
    
    @IBOutlet var loadingView: UIView!
    var loadOverlay: LoadingView!
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var backgroundCheeseLeftConstraint: NSLayoutConstraint!
    @IBOutlet var backgroundCheeseRightConstraint: NSLayoutConstraint!
    var backgroundCheeseInitalLeftConstraint: CGFloat!
    var backgroundCheeseInitalRightConstraint: CGFloat!
    var paralaxScaleFactor: CGFloat = 20
    
    @IBOutlet var chatContainer: UIView!
    @IBOutlet var onboardingContainer: UIView!
    @IBOutlet var loginContainer: UIView!
    @IBOutlet var signupContainer: UIView!
    @IBOutlet var showOnboardConstraint: NSLayoutConstraint!
    @IBOutlet var showLoginConstraint: NSLayoutConstraint!
    @IBOutlet var showSignupConstraint: NSLayoutConstraint!
    var chatController: ChatController!
    var onboardingController: OnboardingViewController!
    var loginController: LoginViewController!
    var signupController: SignupViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundCheeseInitalLeftConstraint = backgroundCheeseLeftConstraint.constant
        backgroundCheeseInitalRightConstraint = backgroundCheeseRightConstraint.constant
        
        loadOverlay = LoadingView.instanceFromNib()
        loadingView.addSubview(loadOverlay)
        loadOverlay.autoPinEdgesToSuperviewEdges()
        
        onboardingController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("OnboardingViewController") as! OnboardingViewController
        
        onboardingController.delegate = self
        addChildViewController(onboardingController)
        onboardingContainer.addSubview(onboardingController.view)
        onboardingController.view.autoPinEdgesToSuperviewEdges()
        
        loginController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
        
        loginController.delegate = self
        addChildViewController(loginController)
        loginContainer.addSubview(loginController.view)
        loginController.view.autoPinEdgesToSuperviewEdges()
        
        signupController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SignupViewController") as! SignupViewController
        
        signupController.delegate = self
        addChildViewController(signupController)
        signupContainer.addSubview(signupController.view)
        signupController.view.autoPinEdgesToSuperviewEdges()

        if (Utilities.appDelegate().deviceDidOnboard()) {
            goToLogin()
        }
        
        if (CheddarRequest.currentUser() != nil) {
            didCompleteLogin()
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
    
    func didCompleteLogin() {
        CheddarRequest.currentUserIsVerified({ (isVerified) in
            if (isVerified) {
                self.showChat()
            }
            else {
                self.showSignupWithEmailVerifyScreen()
            }
            }, errorCallback: { (error) in
        })
    }
    
    func goToOnboard() {
        self.showOnboardConstraint.priority = 900
        self.showLoginConstraint.priority = 200
        self.showSignupConstraint.priority = 200
        self.view.layoutIfNeeded()
    }
    
    func showOnboard() {
        UIView.animateWithDuration(0.333) { 
            self.goToOnboard()
        }
    }
    
    func goToLogin() {
        self.showOnboardConstraint.priority = 200
        self.showLoginConstraint.priority = 900
        self.showSignupConstraint.priority = 200
        self.changeBackgroundColor(ColorConstants.iconColors.last!)
        self.view.layoutIfNeeded()
        
        Utilities.appDelegate().setDeviceOnboarded()
    }
    
    func goToSignup() {
        self.showOnboardConstraint.priority = 200
        self.showLoginConstraint.priority = 200
        self.showSignupConstraint.priority = 900
        self.changeBackgroundColor(ColorConstants.iconColors.last!)
        self.view.layoutIfNeeded()
    }
    
    func showSignupWithEmailVerifyScreen() {
        signupController.goToLastPage()
        showSignup()
    }

    // MARK: FullPageScrollDelegate
    
    func changeBackgroundColor(color: UIColor){
        backgroundView.backgroundColor = color
        view.layoutIfNeeded()
    }
    
    func showLogin() {
        UIView.animateWithDuration(0.333) {
            self.goToLogin()
        }
    }
    
    func showSignup() {
        UIView.animateWithDuration(0.333) {
            self.goToSignup()
        }
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
    
    func removeChat() {
        chatController.view.removeFromSuperview()
        chatController.removeFromParentViewController()
        chatController = nil
        
        chatContainer.hidden = true
    }
}

