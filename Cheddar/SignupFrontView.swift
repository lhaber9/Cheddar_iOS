//
//  SignupFrontView.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/10/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class SignupFrontView: FrontPageView {
    
    func leftButtonPress() {
        delegate?.goToPrevPage()
    }
    
    func rightButtonPress() {
        delegate?.goToNextPage()
    }
    
}