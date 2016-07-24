//
//  VerifyEmailViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 7/5/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol VerifyEmailDelegate: class {
    func emailVerified()
    func didLogout()
}

class VerifyEmailViewController: UIViewController {
    
    weak var delegate:VerifyEmailDelegate!
    
    @IBOutlet var logoutButton: CheddarButton!
    @IBOutlet var checkVerificationButton: CheddarButton!
    @IBOutlet var resendEmailButton: CheddarButton!
    
    @IBOutlet var infoLabel: UILabel!
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserverForName("applicationDidBecomeActive", object: nil, queue: nil) { (notification: NSNotification) in
            self.checkVerification()
        }
        
        logoutButton.setSecondaryButton()
        checkVerificationButton.setSecondaryButton()
        resendEmailButton.setSecondaryButton()
        
        infoLabel.textColor = ColorConstants.colorAccent
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "applicationDidBecomeActive", object: nil)
    }
    
    @IBAction func logout() {
        CheddarRequest.logoutUser()
        delegate.didLogout()
    }
    
    @IBAction func checkVerification() {
        checkVerificationButton.displaySpinner()
        
        CheddarRequest.currentUserIsVerified({ (isVerified) in
            self.checkVerificationButton.removeSpinner()
            if (isVerified) {
                self.delegate.emailVerified()
            }
            else {
                self.showInfoLabel("Email is not verified")
            }
            }, errorCallback: { (error) in
                self.checkVerificationButton.removeSpinner()
        })
    }
    
    @IBAction func resendEmail() {
        resendEmailButton.displaySpinner()
        
        CheddarRequest.resendVerificationEmail(CheddarRequest.currentUserId()!, successCallback: { (object) in
                self.resendEmailButton.removeSpinner()
                self.showInfoLabel("Email Sent!")
            }) { (error) in
                self.resendEmailButton.removeSpinner()
                self.showInfoLabel("Error resending email")
        }
    }
    
    func showInfoLabel(text:String) {
        self.infoLabel.text = text
        
        UIView.animateWithDuration(0.333) {
            self.infoLabel.alpha = 1
            self.view.layoutIfNeeded()
        }
        
        NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: #selector(VerifyEmailViewController.hideInfoLabel), userInfo: nil, repeats: false)
    }
    
    func hideInfoLabel() {
        UIView.animateWithDuration(0.333) {
            self.infoLabel.alpha = 0
            self.view.layoutIfNeeded()
        }
    }
    
}