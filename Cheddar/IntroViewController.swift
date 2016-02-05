//
//  IntroViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/4/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class IntroViewController: FrontPageViewController {

    @IBAction func goToNext() {
        if (isNewUser()) {
            delegate?.goToNextPageWithController(RegisterViewController())
        }
        else {
            delegate?.goToNextPageWithController(SelectionViewController())
        }
    }
    
    func isNewUser() -> Bool {
        return true
    }
}
