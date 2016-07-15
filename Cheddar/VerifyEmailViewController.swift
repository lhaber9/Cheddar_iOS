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
    
    @IBOutlet var logoutButton: UIButton!
    @IBOutlet var checkVerificationButton: UIButton!
    @IBOutlet var resendEmailButton: UIButton!
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserverForName("applicationDidBecomeActive", object: nil, queue: nil) { (notification: NSNotification) in
            self.checkVerification()
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: "applicationDidBecomeActive", object: nil)
    }
    
    @IBAction func logout() {
        CheddarRequest.logoutUser()
        delegate.didLogout()
    }
    
    @IBAction func checkVerification() {
        CheddarRequest.currentUserIsVerified({ (isVerified) in
            if (isVerified) {
                self.delegate.emailVerified()
            }
            else {
                
            }
            }, errorCallback: { (error) in
        })
    }
    
    @IBAction func resendEmail() {
        
    }
}