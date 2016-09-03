//
//  LoginSignupViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/29/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
//import Parse

protocol LoginSignupDelegate: class {
    func didCompleteSignup(_ user: PFUser)
    func didCompleteLogin()
    func showLoadingViewWithText(_ text: String)
    func hideLoadingView()
    func showOverlay()
    func hideOverlay()
}

class LoginSignupViewController: UIViewController, LoginDelegate, SignupDelegate, ChangeSchoolDelegate, RegistrationCodeDelegate, ResetPasswordDelegate, UIPopoverPresentationControllerDelegate, VerifyEmailErrorDelegate {
    
    weak var delegate:LoginSignupDelegate!
    
    @IBOutlet var registerButton:CheddarButton!
    @IBOutlet var loginButton:CheddarButton!
    
    @IBOutlet var viewContents: UIView!
    
    @IBOutlet var taglineLabel: UILabel!
    
    @IBOutlet var errorTextContainer: UIView!
    @IBOutlet var errorLabel: UILabel!
    var errorLabelTimer: Timer!
    
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
        errorTextContainer.backgroundColor = ColorConstants.textPrimary
        errorTextContainer.alpha = 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(LoginSignupViewController.keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(LoginSignupViewController.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LoginSignupViewController.deselectTextFields)))
        
        if (Utilities.IS_IPHONE_4_OR_LESS()) {
            buttonsCenterConstraint.constant = 0
        }
        
        view.layoutIfNeeded()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func setupLogin() {
        loginButton.setSecondaryButton()
        
        loginController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        loginController.delegate = self
        addChildViewController(loginController)
        loginContainer.addSubview(loginController.view)
        loginController.view.autoPinEdgesToSuperviewEdges()
    }
    
    func setupRegister() {
        registerButton.setPrimaryButton()
        
        registerController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignupViewController") as! SignupViewController
        registerController.delegate = self
        addChildViewController(registerController)
        registerContainer.addSubview(registerController.view)
        registerController.view.autoPinEdgesToSuperviewEdges()
    }
    
    func deselectTextFields() {
        loginController.deselectTextFields()
        registerController.deselectTextFields()
    }
    
    func reset() {
        showMain()
        loginController.clearPassword()
        registerController.clearPasswords()
    }
    
    func showMain() {
        UIView.animate(withDuration: 0.333) {
            self.loginContainer.alpha = 0
            self.registerContainer.alpha = 0
            self.mainContainer.alpha = 1
        }
    }
    
    @IBAction func showLogin() {
        UIView.animate(withDuration: 0.333) {
            self.loginContainer.alpha = 1
            self.registerContainer.alpha = 0
            self.mainContainer.alpha = 0
        }
    }
    
    @IBAction func showRegister() {
        UIView.animate(withDuration: 0.333) {
            self.loginContainer.alpha = 0
            self.registerContainer.alpha = 1
            self.mainContainer.alpha = 0
        }
    }
    
    func keyboardWillShow(_ notification: Notification) {
        let keyboardHeight: CGFloat = (((notification as NSNotification).userInfo![UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue.height)
        
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
    
    func keyboardWillHide(_ notification: Notification) {
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
    
    func didCompleteSignup(_ user: PFUser) {
        reset()
        delegate.didCompleteSignup(user)
    }
    
    func didCompleteLogin() {
        reset()
        delegate.didCompleteLogin()
    }
    
    func showErrorText(_ text: String) {
        errorLabel.text = text
        UIView.animate(withDuration: 0.333) {
            self.errorTextContainer.alpha = 1
            self.view.layoutIfNeeded()
        }
        
        if (errorLabelTimer != nil) {
            errorLabelTimer.invalidate()
            errorLabelTimer = nil
        }
        
        errorLabelTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(LoginSignupViewController.hideErrorLabel), userInfo: nil, repeats: false)
    }
    
    func hideErrorLabel() {
        errorLabelTimer = nil
        UIView.animate(withDuration: 0.333) {
            self.errorTextContainer.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
    
    func showLoadingViewWithText(_ text: String) {
        delegate.showLoadingViewWithText(text)
    }
    
    func hideLoadingView() {
        delegate.hideLoadingView()
    }
    
    func showResetPasswordView() {
        delegate.showOverlay()
        performSegue(withIdentifier: "showResetPasswordSegue", sender: self)
    }
    
    func showChangeSchoolView() {
        delegate.showOverlay()
        performSegue(withIdentifier: "showChangeSchoolSegue", sender: self)
    }
    
    func showRegistrationCodeView() {
        delegate.showOverlay()
        performSegue(withIdentifier: "showRegistrationCodeSegue", sender: self)
    }
    
    func hidePopup() {
        delegate.hideOverlay()
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: SignupDelegate
    
    func registerNewUser(_ registrationCode:String!) {
        CheddarRequest.registerNewUser(registerController.emailField.text!,
                                       password: registerController.passwordField.text!,
                                       registrationCode: registrationCode,
                                       successCallback: { (user: PFUser) in
                                        
                                        self.deselectTextFields()
                                        self.didCompleteSignup(user)
                                        self.hideLoadingView()
                                        
        }) { (error) in
            
            self.hideLoadingView()
            
            let errorString = error?.userInfo["error"] as! String
            self.showErrorText(errorString)
//            if (errorString == "username " + self.registerController.emailField.text! + " already taken") {
//                self.showErrorText("Email is already taken")
//            } else if (errorString == "invalid email address") {
//                self.showErrorText("Invalid email address")
//            }
        }
    }
    
    // MARK: UIPopoverPresentationControllerDelegate
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showChangeSchoolSegue" {
            let popoverViewController = segue.destination as! ChangeSchoolViewController
            popoverViewController.delegate = self
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
            popoverViewController.popoverPresentationController!.delegate = self
        } else if segue.identifier == "showRegistrationCodeSegue" {
            let popoverViewController = segue.destination as! RegistrationCodeViewController
            popoverViewController.delegate = self
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
            popoverViewController.popoverPresentationController!.delegate = self
        } else if segue.identifier == "showResetPasswordSegue" {
            let popoverViewController = segue.destination as! ResetPasswordViewController
            popoverViewController.delegate = self
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
            popoverViewController.popoverPresentationController!.delegate = self
            popoverViewController.initialEmail = loginController.emailField.text
        }

    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        delegate.hideOverlay()
        self.dismiss(animated: true, completion: nil)
        return true
    }

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        
        // Force popover style
        return UIModalPresentationStyle.none
    }
}
