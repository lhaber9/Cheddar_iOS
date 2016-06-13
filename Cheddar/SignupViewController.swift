//
//  SignupViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/7/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Parse

class SignupViewController: FullPageScrollView, InfoEntryDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPages()
        
        delegate.changeBackgroundColor(ColorConstants.iconColors.first!)
    }
    
    func currentSignupPage() -> SignupFrontView {
        return currentPage() as! SignupFrontView
    }
    
    func setupPages() {
        let chooseSchoolView = ChooseSchoolView.instanceFromNib()
        let infoEntryView = InfoEntryView.instanceFromNib()
        let confimEmailView = ConfirmEmailView.instanceFromNib()
        
        chooseSchoolView.delegate = self
        infoEntryView.infoEntryDelegate = self
        confimEmailView.delegate = self
        
        addPage(chooseSchoolView)
        addPage(infoEntryView)
        addPage(confimEmailView)
    }
    
    @IBAction func rightButtonPress() {
        currentSignupPage().rightButtonPress()
    }
    
    @IBAction func leftButtonPress() {
        currentSignupPage().leftButtonPress()
    }
    
    // MARK: InfoEntryDelegate
    
    func registerNewUser(email: String, password: String) {
        CheddarRequest.registerNewUser(email,
                                       password: password,
            successCallback: { (user: PFUser) in
                self.goToNextPage()
            }) { (error) in
                
        }
    }
}