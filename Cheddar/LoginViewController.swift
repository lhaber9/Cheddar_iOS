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
    func showErrorText(text: String)
    func showRegister()
    func showLoadingViewWithText(text: String)
    func hideLoadingView()
}

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    weak var delegate: LoginDelegate!
    
    @IBOutlet var emailField:CheddarTextField!
    @IBOutlet var passwordField:CheddarTextField!
    
    @IBOutlet var loginButton:CheddarButton!
    @IBOutlet var registerButton:UIButton!
    
    @IBOutlet var keyboardShowingBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.delegate = self
        emailField.textColor = ColorConstants.textPrimary
        passwordField.delegate = self
        passwordField.textColor = ColorConstants.textPrimary
        
        loginButton.setSecondaryButton()
        
        registerButton.setTitleColor(ColorConstants.textPrimary, forState: UIControlState.Normal)
    }
    
    @IBAction func showRegister() {
        delegate.showRegister()
    }
    
    @IBAction func doLogin() {
        delegate.showLoadingViewWithText("Logging in...")
        CheddarRequest.loginUser(emailField.text!,
                                 password: passwordField.text!,
            successCallback: { (user) in
                
                self.deselectTextFields()
                self.delegate.didCompleteLogin()
                
            }) { (error) in
                
                self.delegate.showErrorText("Invalid email/pass combo")
                self.delegate.hideLoadingView()
        }
    }
    
    func keyboardWillShow() {
        registerButton.alpha = 0
        keyboardShowingBottomConstraint.priority = 950
    }
    
    func keyboardWillHide() {
        registerButton.alpha = 1
        keyboardShowingBottomConstraint.priority = 200
    }
    
    func deselectTextFields() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
    }
    
    func clearPassword() {
        passwordField.text = ""
    }
    
    // MARK: TextFieldDelegate
    
    func textFieldDidEndEditing(textField: UITextField) {
        textField.resignFirstResponder()
        textField.layoutIfNeeded()
    }
}