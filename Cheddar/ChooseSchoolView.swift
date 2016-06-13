//
//  ChooseSchoolView.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/7/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class ChooseSchoolView: SignupFrontView {
    
    class func instanceFromNib() -> ChooseSchoolView {
        return UINib(nibName: "ChooseSchoolView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! ChooseSchoolView
    }
    
    override func leftButtonPress() {
        delegate?.showLogin()
    }
    
}