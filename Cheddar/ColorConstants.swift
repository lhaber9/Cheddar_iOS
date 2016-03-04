//
//  Colors.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/20/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class ColorConstants {
    
    static var colorPrimary = UIColor(hex: 0xf06767)
    static var colorPrimaryDark = UIColor(hex: 0x494949)
    static var colorAccent = UIColor(hex: 0xfade52)
    
    static var headerText = UIColor(hex: 0x393939)
    static var headerBackground = UIColor(hex: 0xfafafa)
    static var headerBorder = UIColor(hex: 0xe1e1e1)
    
    static var sendText = UIColor(hex: 0xb4b4b4)
    static var sendBorder = UIColor(hex: 0xe7e7e7)
    static var sendBackground = UIColor(hex: 0xfafafa)
    
    static var presenceText = UIColor(hex: 0xa5a5a5)
    static var aliasLabelText = UIColor(hex: 0x797979)
    static var inboundMessageText = UIColor(hex: 0x464646)
    static var inboundChatBubble = UIColor(hex: 0xd2d2d2)
    static var outboundMessageText = UIColor(hex: 0xffffff)
    static var outboundChatBubble = colorPrimary
    
    static var inboundIcons = [UIColor(hex: 0xffd127),
                               UIColor(hex: 0xffba27),
                               UIColor(hex: 0xff8d27),
                               UIColor(hex: 0xff7327)]
    
    
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