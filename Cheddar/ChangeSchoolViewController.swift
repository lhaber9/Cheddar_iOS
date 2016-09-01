//
//  ChangeSchoolViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 7/11/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol ChangeSchoolDelegate: class {
    func hidePopup()
}

class ChangeSchoolViewController: UIViewController {
    
    weak var delegate:ChangeSchoolDelegate!
    
    @IBOutlet var emailField: UITextField!
    @IBOutlet var schoolField: UITextField!
    
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
        let schoolName = schoolField.text!
        let email = emailField.text!
        
        if (schoolName.isEmpty || email.isEmpty) {
            displayError("Must fill out both fields")
            return
        }
        
        sendButton.displaySpinner()
        
        CheddarRequest.sendSchoolChangeRequest(schoolName, email: email, successCallback: { (object) in
                self.delegate.hidePopup()
                self.sendButton.removeSpinner()
            }) { (error) in
                self.sendButton.removeSpinner()
                self.displayError("Error sending school information")
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
