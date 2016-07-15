//
//  VerifyEmailViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 7/5/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class VerifyEmailViewController: UIViewController {
    
    @IBOutlet var logoutButton: UIButton!
    @IBOutlet var checkVerificationButton: UIButton!
    @IBOutlet var resendEmailButton: UIButton!
    
    @IBAction func logout() {
        
    }
    
    @IBAction func checkVerification() {
        CheddarRequest.currentUserIsVerified({ (isVerified) in
            if (isVerified) {
                
            }
            else {
                
            }
            }, errorCallback: { (error) in
        })
    }
    
    @IBAction func resendEmail() {
        
    }
}