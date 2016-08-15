//
//  AlphaWarningView.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/28/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class AlphaWarningView: FrontPageView {
    
    @IBOutlet var joinButton: CheddarButton!
    @IBOutlet var joinButtonView: UIView!
    
    @IBOutlet var buttonOffsetSmallConstraint: NSLayoutConstraint!
    
    class func instanceFromNib() -> AlphaWarningView {
        return UINib(nibName: "AlphaWarningView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! AlphaWarningView
    }
    
    override func awakeFromNib() {
        if (Utilities.IS_IPHONE_4_OR_LESS()) {
            buttonOffsetSmallConstraint.priority = 950
        }
    }
    
    @IBAction func tapUpButton() {
        finishOnboard()
    }
    
    func finishOnboard() {
//        delegate?.showLogin()
    }
}