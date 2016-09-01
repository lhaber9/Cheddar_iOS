//
//  ChangeSchoolViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 7/11/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Crashlytics

protocol ResetPasswordDelegate: class {
    func hidePopup()
}

class ResetPasswordViewController: UIViewController {
    
    weak var delegate:ResetPasswordDelegate!
    
    @IBOutlet var emailField: UITextField!
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var errorLabel: UILabel!
    
    @IBOutlet var sendButton: CheddarButton!
    
    var errorLabelTimer: NSTimer!
    var initialEmail: String!
    
    override func viewDidLoad() {
        sendButton.setPrimaryButton()
        errorLabel.textColor = ColorConstants.colorAccent
        titleLabel.textColor = ColorConstants.colorAccent
        
        emailField.text = initialEmail
    }
    
    @IBAction func sendTap() {
        let email = emailField.text!
        
        if (email.isEmpty) {
            displayError("Must enter a valid email")
            return
        }
        
        sendButton.displaySpinner()
        
        CheddarRequest.requestPasswordReset(email, successCallback: { (object) in
            self.delegate.hidePopup()
            self.sendButton.removeSpinner()
        }) { (error) in
            self.sendButton.removeSpinner()
            self.displayError("Error resetting password")
        }
    }
    
    func displayError(text: String) {
        errorLabel.text = text
        UIView.animateWithDuration(0.333) {
            self.errorLabel.alpha = 1
            self.view.layoutIfNeeded()
        }
        
        if (errorLabelTimer != nil) {
            errorLabelTimer.invalidate()
            errorLabelTimer = nil
        }
        
        errorLabelTimer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(ChangeSchoolViewController.hideError), userInfo: nil, repeats: false)
    }
    
    func hideError() {
        UIView.animateWithDuration(0.333) {
            self.errorLabel.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
    
}
