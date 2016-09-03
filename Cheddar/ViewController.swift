//
//  ViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/1/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import UIKit
//import Parse
import Crashlytics

class ViewController: UIViewController, UIScrollViewDelegate, IntroDelegate, ChatDelegate, VerifyEmailDelegate {
    
    @IBOutlet var loadingView: UIView!
    var loadOverlay: LoadingView!
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var backgroundCheeseLeftConstraint: NSLayoutConstraint!
    @IBOutlet var huskyImageLeftConstraint: NSLayoutConstraint!
    var backgroundCheeseInitalLeftConstraint: CGFloat!
    var backgroundCheeseInitalRightConstraint: CGFloat!
    var huskyImageInitialLeftConstraint: CGFloat!
    var backgroundParalaxScaleFactor: CGFloat = 5
//    var huskyParalaxScaleFactor: CGFloat = 22
    
    @IBOutlet var overlayContainer: UIView!
    @IBOutlet var overlayContentsContainer: UIView!
    var overlayContentsController: UIViewController!
    
    @IBOutlet var chatContainer: UIView!
    @IBOutlet var introContainer: UIView!
    var chatController: ChatController!
    var introController: IntroViewController!
    
    var shouldShowVerifyEmailScreen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundCheeseInitalLeftConstraint = backgroundCheeseLeftConstraint.constant
        huskyImageInitialLeftConstraint = huskyImageLeftConstraint.constant
        
        loadOverlay = LoadingView.instanceFromNib()
        loadingView.addSubview(loadOverlay)
        loadOverlay.autoPinEdgesToSuperviewEdges()
        
        introController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "IntroViewController") as! IntroViewController
        
        introController.delegate = self
        addChildViewController(introController)
        introContainer.addSubview(introController.view)
        introController.view.autoPinEdgesToSuperviewEdges()

        view.layoutIfNeeded()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if (CheddarRequest.currentUser() != nil) {
            didCompleteLogin()
        }
        else {
            if (Utilities.appDelegate().deviceDidOnboard()) {
                introController.setOnboardingHidden()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if (shouldShowVerifyEmailScreen) {
            self.showVerifyEmailScreen()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var shouldAutorotate: Bool {
        get {
            return chatController != nil
        }
    }
    
    func useSmallerViews() -> Bool {
        return Utilities.IS_IPHONE_4_OR_LESS()
    }
    
    func showVerifyEmailScreen() {
        shouldShowVerifyEmailScreen = true
        performSegue(withIdentifier: "showVerifyEmail", sender: self)
    }
    
    func didCompleteLogin() {
        introController.loginSignupViewController.reset()
        introController.setOnboardingHidden()
        hideLoadingView()
        if let isVerified = CheddarRequest.currentUser()?["emailVerified"] as? Bool {
            self.hideLoadingView()
            if (isVerified) {
                self.showChat(false)
            } else {
                self.showVerifyEmailScreen()
            }
        }
    }
    
    func didCompleteSignup(_ user: PFUser) {
        showVerifyEmailScreen()
        introController.setOnboardingHidden()
    }
    
    func goToLogin() {
        introController.goToLastPageNoAnimation()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showVerifyEmail" {
            let popoverViewController = segue.destination as! VerifyEmailViewController
            popoverViewController.delegate = self
            popoverViewController.errorDelegate = introController.loginSignupViewController
            
            UIView.animate(withDuration: 0.1, animations: {
                self.introController.loginSignupViewController.hideErrorLabel()
                self.introController.loginSignupViewController.viewContents.alpha = 0
                self.view.layoutIfNeeded()
            })
        }
    }

    // MARK: FullPageScrollDelegate
    
    func changeBackgroundColor(_ color: UIColor){
        backgroundView.backgroundColor = color
        view.layoutIfNeeded()
    }
    
    func showChat(_ shouldForceJoin: Bool) {
        if (CheddarRequest.currentUser() == nil) {
            return
        }
        
        chatController = UIStoryboard(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "ChatController") as! ChatController
        
        chatController.delegate = self
        addChildViewController(chatController)
        chatContainer.addSubview(chatController.view)
        chatController.view.autoPinEdgesToSuperviewEdges()
        
        chatContainer.isHidden = false
        
        if (shouldForceJoin) {
            chatController.joinNextAndAnimate()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let backgrounParalaxOffset = scrollView.contentOffset.x / backgroundParalaxScaleFactor;
        backgroundCheeseLeftConstraint.constant  = backgroundCheeseInitalLeftConstraint - backgrounParalaxOffset
        
//        turn off husky scrolling
//
//        let huskyParalaxOffset = scrollView.contentOffset.x / huskyParalaxScaleFactor;
//        huskyImageLeftConstraint.constant = huskyImageInitialLeftConstraint - huskyParalaxOffset
        
        view.layoutIfNeeded()
    }
    
    // MARK: ChatDelegate
    
    func showLoadingViewWithText(_ text: String) {
        loadOverlay.loadingTextLabel.text = text
        UIView.animate(withDuration: 0.333) { () -> Void in
            self.loadingView.alpha = 1
            self.loadingView.isHidden = false
        }
    }
    
    func hideLoadingView() {
        UIView.animate(withDuration: 0.333) { () -> Void in
            self.loadingView.alpha = 0
            self.loadingView.isHidden = true
        }
    }
    
    func showOverlay() {
        UIView.animate(withDuration: 0.33, animations: {
            self.overlayContainer.isHidden = false
            self.overlayContainer.alpha = 1
            self.view.layoutIfNeeded()
        })
    }
    
    func hideOverlay() {
        UIView.animate(withDuration: 0.33, animations: {
            self.overlayContainer.alpha = 0
            self.view.layoutIfNeeded()
        }) { (completed: Bool) in
            self.overlayContainer.isHidden = true
        }
    }
    
    func showOverlayContents(_ viewController: UIViewController) {
        addChildViewController(viewController)
        overlayContentsContainer.addSubview(viewController.view)
        viewController.view.autoPinEdgesToSuperviewEdges()
        overlayContentsController = viewController
        self.view.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.33, animations: {
            self.overlayContentsContainer.isHidden = false
            self.overlayContentsContainer.alpha = 1
            self.view.layoutIfNeeded()
        })
    }
    
    func hideOverlayContents() {
        UIView.animate(withDuration: 0.33, animations: {
            self.overlayContentsContainer.alpha = 0
            self.view.layoutIfNeeded()
        }) { (completed: Bool) in
            self.overlayContentsContainer.isHidden = true
            self.overlayContentsController?.view.removeFromSuperview()
            self.overlayContentsController?.removeFromParentViewController()
            self.overlayContentsController = nil
        }
    }
    
    func removeChat() {
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        goToLogin()
        introController.loginSignupViewController.reset()
        
        chatController.view.removeFromSuperview()
        chatController.removeFromParentViewController()
        chatController = nil
        
        chatContainer.isHidden = true
    }
    
    // MARK: VerifyEmailDelegate
    
    func didLogout() {
        shouldShowVerifyEmailScreen = false
        UIView.animate(withDuration: 0.1, animations: {
            self.introController.loginSignupViewController.viewContents.alpha = 1
            self.view.layoutIfNeeded()
        })
        dismiss(animated: true, completion: nil)
    }
    
    func emailVerified() {
        shouldShowVerifyEmailScreen = false
        dismiss(animated: true) {
            UIView.animate(withDuration: 0.1, animations: {
                self.introController.loginSignupViewController.viewContents.alpha = 1
                self.view.layoutIfNeeded()
            })
            self.showChat(true)
        }
    }
}

