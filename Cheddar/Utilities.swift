//
//  Utilities.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/26/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class Utilities {
    class func IS_IPHONE_4_OR_LESS() -> Bool { return IS_IPHONE() && (UIScreen.mainScreen().bounds.size.height < 568.0) }
    class func IS_IPHONE_5() -> Bool { return IS_IPHONE() && (UIScreen.mainScreen().bounds.size.height == 568.0) }
    class func IS_IPHONE_6() -> Bool { return IS_IPHONE() && (UIScreen.mainScreen().bounds.size.height == 667.0) }
    class func IS_IPHONE_6_PLUS() -> Bool { return IS_IPHONE() && (UIScreen.mainScreen().bounds.size.height == 736.0) }
    class func IS_IPAD() -> Bool { return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad) }
    class func IS_IPHONE() -> Bool { return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Phone) }
    
    class func appDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }
}