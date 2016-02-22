//
//  Colors.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/20/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class ColorConstants {
    static var colorPrimary = UIColor(hex: 0xffd666)
    static var colorPrimaryDark = UIColor(hex: 0x2d2d2d)
    static var colorAccent = UIColor(hex: 0xF26667)
    static var matchItemSelected = UIColor(hex: 0x1000)
    static var matchItemUnselected = UIColor(hex: 0x0000)
    static var solidGray = UIColor(hex: 0xe5e5e5)
    static var dividerGray = UIColor(hex: 0x1000)
}

extension UIColor {
    
    convenience init(hex: Int) {
        
        let components = (
            R: CGFloat((hex >> 16) & 0xff) / 255,
            G: CGFloat((hex >> 08) & 0xff) / 255,
            B: CGFloat((hex >> 00) & 0xff) / 255
        )
        
        self.init(red: components.R, green: components.G, blue: components.B, alpha: 1)
        
    }
    
}