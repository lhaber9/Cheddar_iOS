//
//  RegistrationCodeViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 7/24/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol RegistrationCodeDelegate: class {
    func hidePopup()
    func registerNewUser(registrationCode:String!)
}

class RegistrationCodeViewController: UIViewController {
    
    weak var delegate:RegistrationCodeDelegate!
    
    @IBOutlet var codeField: UITextField!
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var errorLabel: UILabel!
    
    @IBOutlet var sendButton: CheddarButton!
    
    var errorLabelTimer: NSTimer!
    
    override func viewDidLoad() {
        sendButton.setPrimaryButton()
        errorLabel.textColor = ColorConstants.colorAccent
        titleLabel.textColor = ColorConstants.colorAccent
    }
    
    @IBAction func sendTap() {
        
        sendButton.displaySpinner()
        
        let code = codeField.text!
        
        CheddarRequest.checkRegistrationCode(code, successCallback: { (object) in
            self.sendButton.removeSpinner()
            if (object.boolValue!) {
                self.delegate.hidePopup()
                self.delegate.registerNewUser(code)
            } else {
                self.displayError("Unknown registration code")
            }
        }) { (error) in
            self.sendButton.removeSpinner()
            self.displayError("Error validating registration code")
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