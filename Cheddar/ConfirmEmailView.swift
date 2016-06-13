//
//  ConfirmEmailView.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/7/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class ConfirmEmailView: SignupFrontView {
    
    @IBOutlet var confirmedLabel: UILabel!
    
    class func instanceFromNib() -> ConfirmEmailView {
        return UINib(nibName: "ConfirmEmailView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! ConfirmEmailView
    }
    
    @IBAction func checkVerifyEmail() {
        
        CheddarRequest.currentUserIsVerified({ (isVerified) in
            
            if (isVerified) {
                self.confirmedLabel.text = "YES"
            }
            else {
                self.confirmedLabel.text = "NO"
            }
            
            }) { (error) in
               
                self.confirmedLabel.text = "NO"
        }
    }
}