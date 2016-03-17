//
//  IntroViewController.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/4/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class IntroViewController: FrontPageViewController {

    init () {
        super.init(nibName: "IntroView", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func goToNext() {
        goToNextPageWithController(SelectionViewController())
    }
    
    func isNewUser() -> Bool {
        return true
    }
}
