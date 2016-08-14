//
//  Colors.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/20/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class ColorConstants {
    
    static var whiteColor = UIColor(hex: 0xFFFFFF)
    
    static var colorPrimary = UIColor(hex: 0xfade52)
    static var colorAccent = UIColor(hex: 0xf06767)

    static var textPrimary = UIColor(hex: 0x494949)
    static var textSecondary = UIColor(hex: 0x494949)
    
    static var chatNavBackground = UIColor(hex: 0xF0F0F0)
    static var chatNavBorder = UIColor(hex: 0xdadada)
    
    static var headerBorder = UIColor(hex: 0xe1e1e1)
    
    static var presenceText = UIColor(hex: 0xa0a0a0)
    static var aliasLabelText = UIColor(hex: 0xa0a0a0)
    static var timestampText = UIColor(hex: 0xa0a0a0)
    
    static var inboundMessageText = textPrimary
    static var inboundChatBubble = UIColor(hex: 0xEFEFEF)
    static var outboundMessageText = UIColor(hex: 0xffffff)
    static var outboundChatBubble = colorAccent
    static var outboundChatBubbleSending = UIColor(hex: 0xF26667)
    static var outboundChatBubbleFail = UIColor(hex: 0xEFEFEF)
    
    static var matchItemSelected = UIColor(hex: 0x1000)
    static var matchItemUnselected = UIColor(hex: 0x0000)
    static var solidGray = UIColor(hex: 0xe5e5e5)
    static var dividerGray = UIColor(hex: 0x1000)
    
    static var iconColors = [   UIColor(hex: 0xff7727),
                                UIColor(hex: 0xff9227),
                                UIColor(hex: 0xffad27),
                                UIColor(hex: 0xffc827),
                                UIColor(hex: 0xffe327)]
    
    static func iconColorForFloat(number: CGFloat) -> UIColor {
        
        let components0 = CGColorGetComponents(iconColors[Int(floor(number))].CGColor)
        let red0 = components0[0];
        let green0 = components0[1];
        let blue0 = components0[2];
        
        let components1 = CGColorGetComponents(iconColors[Int(ceil(number))].CGColor)
        let red1 = components1[0];
        let green1 = components1[1];
        let blue1 = components1[2];
        
        let percentBetween = number - floor(number)
        
        let red = red0 + ((red1 - red0) * percentBetween)
        let green = green0 + ((green1 - green0) * percentBetween)
        let blue = blue0 + ((blue1 - blue0) * percentBetween)
        
        return UIColor(colorLiteralRed: Float(red), green: Float(green), blue: Float(blue), alpha: 1)
    }
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