//
//  LockedBackgroundColorView.swift
//  Cheddar
//
//  Created by Lucas Haber on 5/19/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation


class LockedBackgroundColorView:UIView {
    
    var lockedBackgroundColor:UIColor {
        set {
            super.backgroundColor = newValue
        }
        get {
            return super.backgroundColor!
        }
    }
    
    override var backgroundColor:UIColor? {
        set {
        }
        get {
            return super.backgroundColor
        }
    }
    
}