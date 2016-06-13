//
//  InfoEntryView.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/7/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Parse

protocol InfoEntryDelegate: FrontPageViewDelegate {
    func registerNewUser(email: String, password: String)
}

class InfoEntryView: SignupFrontView {
    
    weak var infoEntryDelegate: InfoEntryDelegate?
    
    @IBOutlet var emailField: UITextField!
    @IBOutlet var passwordField: UITextField!
    @IBOutlet var passwordConfirmField: UITextField!
    
    override func awakeFromNib() {
        emailField.setBottomBorder(ColorConstants.textPrimary)
        passwordField.setBottomBorder(ColorConstants.textPrimary)
        passwordConfirmField.setBottomBorder(ColorConstants.textPrimary)
    }
    
    override func rightButtonPress() {
        if (valdateForm()) {
            doSignup()
        }
    }
    
    override func leftButtonPress() {
        infoEntryDelegate?.goToPrevPage()
    }
    
    class func instanceFromNib() -> InfoEntryView {
        return UINib(nibName: "InfoEntryView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! InfoEntryView
    }
    
    func doSignup() {
        infoEntryDelegate?.registerNewUser(emailField.text!, password: passwordField.text!)
    }
    
    func valdateForm() -> Bool {
        if (emailField.text?.isEmpty == true) {
            
            return false
        } else if (passwordField.text?.isEmpty == true) {
            
            return false
        } else if (passwordConfirmField.text?.isEmpty == true) {
            
            return false
        }
        
        if (!isValidEmail(emailField.text!)) {
            return false
        }
        
        if (passwordField.text! != passwordConfirmField.text!) {
            return false
        }
        
        return true
    }
    
    func isValidEmail(email: String) -> Bool {
        let elements = email.componentsSeparatedByString("@")
        if (elements[1] == "husky.neu.edu") {
            return true
        }
        return false
    }
}