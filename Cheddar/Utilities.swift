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
    class func IS_IPHONE_5_OR_LESS() -> Bool { return IS_IPHONE_4_OR_LESS() || IS_IPHONE_5() }
    class func IS_IPHONE_5() -> Bool { return IS_IPHONE() && (UIScreen.mainScreen().bounds.size.height == 568.0) }
    class func IS_IPHONE_6() -> Bool { return IS_IPHONE() && (UIScreen.mainScreen().bounds.size.height == 667.0) }
    class func IS_IPHONE_6_PLUS() -> Bool { return IS_IPHONE() && (UIScreen.mainScreen().bounds.size.height == 736.0) }
    class func IS_IPAD() -> Bool { return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Pad) }
    class func IS_IPHONE() -> Bool { return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.Phone) }
    
    class func appDelegate() -> AppDelegate {
        return UIApplication.sharedApplication().delegate as! AppDelegate
    }
    
    class func removeAllUserData() {
        ChatEvent.removeAll()
        ChatRoom.removeAll()
        Alias.removeAll()
    }
    
    class func envName() -> String {
        return NSBundle.mainBundle().infoDictionary!["SchemeName"] as! String
    }
    
    class func formatDate(date: NSDate) -> String {
        let dateFor: NSDateFormatter = NSDateFormatter()
        
        let midnight = NSCalendar.currentCalendar().startOfDayForDate(NSDate())
        if (midnight.compare(date) == NSComparisonResult.OrderedAscending) {
            dateFor.dateFormat = "h:mm a"
        }
        else {
            let threeDaysAgo = NSDate().dateByAddingTimeInterval(-1 * 3 * 24 * 3600)
            if (threeDaysAgo.compare(date) == NSComparisonResult.OrderedAscending) {
                dateFor.dateFormat = "EEE"
            }
            else {
                dateFor.dateFormat = "MMM d"
            }
        }

        return dateFor.stringFromDate(date)
    }
    
    class func getKeyConstant(name: String) -> String! {
        var keys: NSDictionary?
        
        if let path = NSBundle.mainBundle().pathForResource("Keys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        if let dict = keys![envName()] {
            return (dict[name] as? String)!
        }
        return nil
    }
}