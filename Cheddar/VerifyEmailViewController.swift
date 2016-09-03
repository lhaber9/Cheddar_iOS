//
//  VerifyEmailViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 7/5/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Crashlytics

protocol VerifyEmailDelegate: class {
    func emailVerified()
    func didLogout()
}

protocol VerifyEmailErrorDelegate: class {
    func showErrorText(_ text: String)
}

class VerifyEmailViewController: UIViewController {
    
    weak var delegate:VerifyEmailDelegate!
    weak var errorDelegate:VerifyEmailErrorDelegate!
    
    @IBOutlet var logoutButton: CheddarButton!
    @IBOutlet var checkVerificationButton: CheddarButton!
    @IBOutlet var resendEmailButton: CheddarButton!
    
    @IBOutlet var buttonsCenterConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "applicationDidBecomeActive"), object: nil, queue: nil) { (notification: Notification) in
            self.checkVerification()
        }
        
        logoutButton.setSecondaryButton()
        checkVerificationButton.setSecondaryButton()
        resendEmailButton.setSecondaryButton()
        
        if (Utilities.IS_IPHONE_4_OR_LESS()) {
            buttonsCenterConstraint.constant = -5
        } else if (Utilities.IS_IPHONE_5()) {
            buttonsCenterConstraint.constant = 25
        }
        
        view.layoutIfNeeded()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "applicationDidBecomeActive"), object: nil)
    }
    
    @IBAction func logout() {
        logoutButton.displaySpinner()
        
        CheddarRequest.logoutUser({
            self.logoutButton.removeSpinner()
            Utilities.removeAllUserData()
            self.delegate.didLogout()
        }) { (error) in
            self.logoutButton.removeSpinner()
            self.errorDelegate.showErrorText("error loggin out")
        }
    }
    
    @IBAction func checkVerification() {
        checkVerificationButton.displaySpinner()
        
        CheddarRequest.currentUserIsVerified({ (isVerified) in
            self.checkVerificationButton.removeSpinner()
            if (isVerified) {
                self.delegate.emailVerified()
            }
            else {
                self.errorDelegate.showErrorText("please check your email for the verification link")
            }
            }, errorCallback: { (error) in
                self.checkVerificationButton.removeSpinner()
        })
    }
    
    @IBAction func resendEmail() {
        resendEmailButton.displaySpinner()
        
        CheddarRequest.resendVerificationEmail(CheddarRequest.currentUserId()!, successCallback: { (object) in
                self.resendEmailButton.removeSpinner()
                self.errorDelegate.showErrorText("verification email has been sent to " + (CheddarRequest.currentUser()?.email)!)
            }) { (error) in
                self.resendEmailButton.removeSpinner()
                self.errorDelegate.showErrorText("Error resending email")
        }
    }
}
