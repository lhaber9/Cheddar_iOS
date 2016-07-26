////
////  SignupViewController.swift
////  Cheddar
////
////  Created by Lucas Haber on 6/7/16.
////  Copyright © 2016 Lucas Haber. All rights reserved.
////

import Foundation
import Parse

protocol SignupDelegate: class {
    func didCompleteSignup(user: PFUser)
    func showErrorText(text: String)
    func showLogin()
    func showLoadingViewWithText(text: String)
    func hideLoadingView()
    func showChangeSchoolView()
    func showRegistrationCodeView()
    func registerNewUser(registrationCode:String!)
}

class SignupViewController: UIViewController, UITextFieldDelegate {
    
    weak var delegate: SignupDelegate!
    
    @IBOutlet var emailField:CheddarTextField!
    @IBOutlet var passwordField:CheddarTextField!
    @IBOutlet var confirmPasswordField:CheddarTextField!
    
    @IBOutlet var registerButton:CheddarButton!
    @IBOutlet var goToLoginButton:UIButton!
    @IBOutlet var changeSchoolButton:UIButton!
    
    @IBOutlet var keyboardShowingBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emailField.delegate = self
        emailField.textColor = ColorConstants.textPrimary
        passwordField.delegate = self
        passwordField.textColor = ColorConstants.textPrimary
        confirmPasswordField.delegate = self
        confirmPasswordField.textColor = ColorConstants.textPrimary
        
        registerButton.setPrimaryButton()
        
        goToLoginButton.setTitleColor(ColorConstants.textPrimary, forState: UIControlState.Normal)
        changeSchoolButton.setTitleColor(ColorConstants.textPrimary, forState: UIControlState.Normal)
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
            if (emailField.text!.containsString("@husky.neu.edu")) {
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
        goToLoginButton.alpha = 0
        changeSchoolButton.alpha = 0
        keyboardShowingBottomConstraint.priority = 950
    }
    
    func keyboardWillHide() {
        goToLoginButton.alpha = 1
        changeSchoolButton.alpha = 1
        keyboardShowingBottomConstraint.priority = 200
    }
    
    func deselectTextFields() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        confirmPasswordField.resignFirstResponder()
    }
    
    func clearTextFields() {
        emailField.text = ""
        passwordField.text = ""
        confirmPasswordField.text = ""
    }
    
    func showErrorText(text: String) {
        delegate.showErrorText(text)
    }
    
    func registerNewUser(email: String, password: String) {
        delegate.registerNewUser(nil)
    }
    
    func getEntryErrors() -> String {
        let emailText = emailField.text!
        let passwordText = passwordField.text!
        let confirmPasswordText = confirmPasswordField.text!
        
        if (emailText.isEmpty) {
            return "Must supply email"
        }
        if (passwordText.isEmpty) {
            return "Must supply password"
        }
        if (confirmPasswordText.isEmpty) {
            return "Must confirm password"
        }
        if (passwordText != confirmPasswordText) {
            return "Passwords must match"
        }
        
        return ""
    }
    
    // MARK: TextFieldDelegate
    
    func textFieldDidEndEditing(textField: UITextField) {
        textField.resignFirstResponder()
        textField.layoutIfNeeded()
    }
}