//
//  LoginSignupViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/29/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Parse

protocol LoginSignupDelegate: class {
    func didCompleteSignup(user: PFUser)
    func didCompleteLogin()
    func showLoadingViewWithText(text: String)
    func hideLoadingView()
    func showOverlay()
    func hideOverlay()
}

class LoginSignupViewController: UIViewController, LoginDelegate, SignupDelegate, UIPopoverPresentationControllerDelegate {
    
    weak var delegate:LoginSignupDelegate!
    
    @IBOutlet var registerButton:CheddarButton!
    @IBOutlet var loginButton:CheddarButton!
    
    @IBOutlet var taglineLabel: UILabel!
    
    @IBOutlet var errorTextContainer: UIView!
    @IBOutlet var errorLabel: UILabel!
    
    @IBOutlet var registerContainer: UIView!
    @IBOutlet var loginContainer: UIView!
    @IBOutlet var mainContainer: UIView!
    
    @IBOutlet var buttonsCenterConstraint: NSLayoutConstraint!
    
    @IBOutlet var topConstraint: NSLayoutConstraint!
    @IBOutlet var topConstraintKeyboardSmallSize: NSLayoutConstraint!
    @IBOutlet var topConstraintKeyboard: NSLayoutConstraint!
    @IBOutlet var bottomConstraint: NSLayoutConstraint!
    @IBOutlet var bottomConstraintKeyboard: NSLayoutConstraint!
    
    @IBOutlet var cheddarLabelKeyboardConstraint: NSLayoutConstraint!
    
    var registerController: SignupViewController!
    var loginController: LoginViewController!
    
    override func viewDidLoad() {
    
        setupLogin()
        setupRegister()
        
        errorTextContainer.layer.cornerRadius = errorTextContainer.bounds.size.height / 2
        errorTextContainer.alpha = 0
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginSignupViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginSignupViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LoginSignupViewController.deselectTextFields)))
        
        if (Utilities.IS_IPHONE_4_OR_LESS()) {
            buttonsCenterConstraint.constant = 0
        }
        
        view.layoutIfNeeded()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func setupLogin() {
        loginButton.setSecondaryButton()
        
        loginController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
        loginController.delegate = self
        addChildViewController(loginController)
        loginContainer.addSubview(loginController.view)
        loginController.view.autoPinEdgesToSuperviewEdges()
    }
    
    func setupRegister() {
        registerButton.setPrimaryButton()
        
        registerController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SignupViewController") as! SignupViewController
        registerController.delegate = self
        addChildViewController(registerController)
        registerContainer.addSubview(registerController.view)
        registerController.view.autoPinEdgesToSuperviewEdges()
    }
    
    func deselectTextFields() {
        loginController.deselectTextFields()
        registerController.deselectTextFields()
    }
    
    @IBAction func showLogin() {
        UIView.animateWithDuration(0.333) {
            self.loginContainer.alpha = 1
            self.registerContainer.alpha = 0
            self.mainContainer.alpha = 0
        }
    }
    
    @IBAction func showRegister() {
        UIView.animateWithDuration(0.333) {
            self.loginContainer.alpha = 0
            self.registerContainer.alpha = 1
            self.mainContainer.alpha = 0
        }
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let keyboardHeight: CGFloat = (notification.userInfo![UIKeyboardFrameEndUserInfoKey]?.CGRectValue.height)!
        
        topConstraintKeyboard.constant = self.topConstraint.constant - (keyboardHeight / 3)
        bottomConstraintKeyboard.constant = keyboardHeight + 5
        
        topConstraintKeyboard.priority = 950
        bottomConstraintKeyboard.priority = 950
        
        registerController.keyboardWillShow()
        loginController.keyboardWillShow()
        
        if (Utilities.IS_IPHONE_4_OR_LESS()) {
            taglineLabel.alpha = 0
            cheddarLabelKeyboardConstraint.priority = 950
            topConstraintKeyboardSmallSize.priority = 950
        } else {
            topConstraintKeyboard.priority = 950
        }
        
        view.layoutIfNeeded()
    }
    
    func keyboardWillHide(notification: NSNotification) {
        topConstraintKeyboard.priority = 200
        topConstraintKeyboardSmallSize.priority = 200
        bottomConstraintKeyboard.priority = 200
        
        registerController.keyboardWillHide()
        loginController.keyboardWillHide()
        
        if (Utilities.IS_IPHONE_4_OR_LESS()) {
            taglineLabel.alpha = 1
            cheddarLabelKeyboardConstraint.priority = 200
        }
        
        view.layoutIfNeeded()
    }
    
    func didCompleteSignup(user: PFUser) {
        delegate.didCompleteSignup(user)
    }
    
    func didCompleteLogin() {
        delegate.didCompleteLogin()
    }
    
    func showErrorText(text: String) {
        errorLabel.text = text
        UIView.animateWithDuration(0.333) {
            self.errorTextContainer.alpha = 1
            self.view.layoutIfNeeded()
        }
        
        NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(LoginSignupViewController.hideErrorLabel), userInfo: nil, repeats: false)
    }
    
    func hideErrorLabel() {
        UIView.animateWithDuration(0.333) {
            self.errorTextContainer.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
    
    func showLoadingViewWithText(text: String) {
        delegate.showLoadingViewWithText(text)
    }
    
    func hideLoadingView() {
        delegate.hideLoadingView()
    }
    
    func showChangeSchoolView() {
        delegate.showOverlay()
        performSegueWithIdentifier("showChangeSchoolSegue", sender: self)
    }
    
    func hideChangeSchoolView() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: UIPopoverPresentationControllerDelegate
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showChangeSchoolSegue" {
            let popoverViewController = segue.destinationViewController as! ChangeSchoolViewController
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController!.delegate = self
        }
    }
    
    func popoverPresentationControllerWillDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        delegate.hideOverlay()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        
        // Force popover style
        return UIModalPresentationStyle.None
    }
}