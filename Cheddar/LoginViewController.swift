////
////  LoginViewController.swift
////  Cheddar
////
////  Created by Lucas Haber on 6/6/16.
////  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Crashlytics

protocol LoginDelegate: class {
    func didCompleteLogin()
    func showErrorText(_ text: String)
    func showRegister()
    func showLoadingViewWithText(_ text: String)
    func showResetPasswordView()
    func hideLoadingView()
}

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    weak var delegate: LoginDelegate!
    
    @IBOutlet var emailField:CheddarTextField!
    @IBOutlet var passwordField:CheddarTextField!
    
    @IBOutlet var loginButton:CheddarButton!
    @IBOutlet var registerButton:UIButton!
    @IBOutlet var resetPasswordButton:UIButton!
    
    @IBOutlet var hiddenButtonsBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.delegate = self
        emailField.textColor = ColorConstants.textPrimary
        passwordField.delegate = self
        passwordField.textColor = ColorConstants.textPrimary
        
        loginButton.setSecondaryButton()
        
        registerButton.setTitleColor(ColorConstants.textPrimary, for: UIControlState.normal)
        resetPasswordButton.setTitleColor(ColorConstants.textPrimary, for: UIControlState.normal)
    }
    
    @IBAction func showRegister() {
        delegate.showRegister()
    }
    
    @IBAction func resetPassword() {
        delegate.showResetPasswordView()
    }
    
    @IBAction func doLogin() {
        delegate.showLoadingViewWithText("Logging in...")
        CheddarRequest.loginUser(emailField.text!,
                                 password: passwordField.text!,
            successCallback: { (user) in
                
                self.deselectTextFields()
                self.delegate.didCompleteLogin()
                
            }) { (error) in
                
                self.delegate.showErrorText("Invalid email or password")
                self.delegate.hideLoadingView()
        }
    }
    
    func keyboardWillShow() {
        if (Utilities.IS_IPHONE_5_OR_LESS()) {
                registerButton.alpha = 0
                resetPasswordButton.alpha = 0
                hiddenButtonsBottomConstraint.priority = 950
        }
    }
    
    func keyboardWillHide() {
        if (Utilities.IS_IPHONE_5_OR_LESS()) {
            registerButton.alpha = 1
            resetPasswordButton.alpha = 1
            hiddenButtonsBottomConstraint.priority = 200
        }
    }
    
    func deselectTextFields() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
    
    func clearPassword() {
        passwordField.text = ""
    }
    
    // MARK: TextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        textField.layoutIfNeeded()
    }
}
