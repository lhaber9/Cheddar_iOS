//
//  LoginViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/6/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol LoginDelegate: class {
    func showSignup()
    func didCompleteLogin()
    func showChat()
    func changeBackgroundColor(color:UIColor)
}

class LoginViewController: UIViewController {
    
    weak var delegate: LoginDelegate!
    
    @IBOutlet var loginEntryView:UIView!
    @IBOutlet var emailField:UITextField!
    @IBOutlet var passwordField:UITextField!
    
    @IBOutlet var singupButton:UIView!
    @IBOutlet var loginButton:UIView!
    @IBOutlet var cancelButton:UIView!
    
    @IBOutlet var loginButtonFullSizeLeftConstraint: NSLayoutConstraint!
    @IBOutlet var loginButtonHalfSizeLeftConstraint: NSLayoutConstraint!
    
    @IBOutlet var cancelButtonFullSizeRightConstraint: NSLayoutConstraint!
    @IBOutlet var cancelButtonHalfSizeRightConstraint: NSLayoutConstraint!
    
    @IBOutlet var viewCenterYConstraint: NSLayoutConstraint!
    
    var isShowingLogin: Bool = false
    
    override func viewDidLoad() {
        emailField.setBottomBorder(ColorConstants.textPrimary)
        passwordField.setBottomBorder(ColorConstants.textPrimary)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewController.keyboardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(LoginViewController.keyboardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let keyboardHeight: CGFloat = (notification.userInfo![UIKeyboardFrameEndUserInfoKey]?.CGRectValue.height)!
        
        viewCenterYConstraint.constant = -1 * (keyboardHeight / 2)
        self.view.layoutIfNeeded()
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        viewCenterYConstraint.constant = 0
        self.view.layoutIfNeeded()
    }
    
    @IBAction func showLoginFields() {
        UIView.animateWithDuration(0.45, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.singupButton.alpha = 0
            self.loginEntryView.alpha = 1
            self.cancelButton.alpha = 1
            
            self.loginButtonFullSizeLeftConstraint.priority = 200
            self.loginButtonHalfSizeLeftConstraint.priority = 900
            
            self.cancelButtonFullSizeRightConstraint.priority = 200
            self.cancelButtonHalfSizeRightConstraint.priority = 900
            
            self.view.layoutIfNeeded()
            }, completion: nil)
        isShowingLogin = true
    }
    
    @IBAction func hideLoginFields() {
        UIView.animateWithDuration(0.45, delay: 0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveEaseInOut, animations: {
            self.singupButton.alpha = 1
            self.loginEntryView.alpha = 0
            self.cancelButton.alpha = 0
            
            self.loginButtonFullSizeLeftConstraint.priority = 900
            self.loginButtonHalfSizeLeftConstraint.priority = 200
            
            self.cancelButtonFullSizeRightConstraint.priority = 900
            self.cancelButtonHalfSizeRightConstraint.priority = 200
            
            self.view.layoutIfNeeded()
            }, completion: nil)
        isShowingLogin = false
    }
    
    @IBAction func showSignup() {
        delegate.showSignup()
    }
    
    @IBAction func tapLogin() {
        if (isShowingLogin) {
            doLogin()
        }
        else {
            showLoginFields()
        }
    }
    
    func doLogin() {
        CheddarRequest.loginUser(emailField.text!,
                                 password: passwordField.text!,
            successCallback: { (user) in
                
                self.delegate.didCompleteLogin()
                
            }) { (error) in
        }
    }
}

extension UITextField {
    func setBottomBorder(color:UIColor) {
        self.borderStyle = UITextBorderStyle.None;
        let border = CALayer()
        let width = CGFloat(1.0)
        border.borderColor = color.CGColor
        border.frame = CGRect(x: 0, y: self.frame.size.height - width,   width:  self.frame.size.width, height: self.frame.size.height)
        
        border.borderWidth = width
        self.layer.addSublayer(border)
        self.layer.masksToBounds = false
    }
    
}