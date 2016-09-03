////
////  SignupViewController.swift
////  Cheddar
////
////  Created by Lucas Haber on 6/7/16.
////  Copyright © 2016 Lucas Haber. All rights reserved.
////

import Foundation
//import Parse

protocol SignupDelegate: class {
    func didCompleteSignup(_ user: PFUser)
    func showErrorText(_ text: String)
    func showLogin()
    func showLoadingViewWithText(_ text: String)
    func hideLoadingView()
    func showChangeSchoolView()
    func showRegistrationCodeView()
    func registerNewUser(_ registrationCode:String!)
}

class SignupViewController: UIViewController, UITextFieldDelegate {
    
    weak var delegate: SignupDelegate!
    
    @IBOutlet var emailField:CheddarTextField!
    @IBOutlet var passwordField:CheddarTextField!
    @IBOutlet var confirmPasswordField:CheddarTextField!
    
    @IBOutlet var registerButton:CheddarButton!
    @IBOutlet var goToLoginButton:UIButton!
    @IBOutlet var changeSchoolButton:UIButton!
    
    @IBOutlet var hiddenButtonsBottomConstraint: NSLayoutConstraint!
    
    var minimumPasswordLength = 6
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.delegate = self
        emailField.textColor = ColorConstants.textPrimary
        passwordField.delegate = self
        passwordField.textColor = ColorConstants.textPrimary
        confirmPasswordField.delegate = self
        confirmPasswordField.textColor = ColorConstants.textPrimary
        
        registerButton.setPrimaryButton()
        
        goToLoginButton.setTitleColor(ColorConstants.textPrimary, for: UIControlState.normal)
        changeSchoolButton.setTitleColor(ColorConstants.textPrimary, for: UIControlState.normal)
    }
    
    @IBAction func showLogin() {
        delegate.showLogin()
    }
    
    @IBAction func showChangeSchoolView() {
        delegate.showChangeSchoolView()
    }
    
    @IBAction func tapRegister() {
        let entryErrors = getEntryErrors()
        if (entryErrors.isEmpty) {
            if (emailField.text!.contains("@husky.neu.edu")) {
                delegate.showLoadingViewWithText("Registering...")
                registerNewUser(emailField.text!, password: passwordField.text!)
            } else {
                delegate.showRegistrationCodeView()
            }
        }
        else {
            showErrorText(entryErrors)
        }
    }
    
    func keyboardWillShow() {
        if (Utilities.IS_IPHONE_5_OR_LESS()) {
            goToLoginButton.alpha = 0
            changeSchoolButton.alpha = 0
            hiddenButtonsBottomConstraint.priority = 950
        }
    }
    
    func keyboardWillHide() {
        if (Utilities.IS_IPHONE_5_OR_LESS()) {
            goToLoginButton.alpha = 1
            changeSchoolButton.alpha = 1
            hiddenButtonsBottomConstraint.priority = 200
        }
    }
    
    func deselectTextFields() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        confirmPasswordField.resignFirstResponder()
    }
    
    func clearPasswords() {
        passwordField.text = ""
        confirmPasswordField.text = ""
    }
    
    func showErrorText(_ text: String) {
        delegate.showErrorText(text)
    }
    
    func registerNewUser(_ email: String, password: String) {
        delegate.registerNewUser(nil)
    }
    
    func getEntryErrors() -> String {
        let emailText = emailField.text!
        let passwordText = passwordField.text!
        let confirmPasswordText = confirmPasswordField.text!
        
        if (emailText.isEmpty) {
            return "Invalid email"
        }
        if (passwordText.characters.count < minimumPasswordLength) {
            return "Passwords must be 6 characters"
        }
        if (passwordText != confirmPasswordText) {
            return "Passwords don't match"
        }
        
        return ""
    }
    
    // MARK: TextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        textField.layoutIfNeeded()
    }
}
