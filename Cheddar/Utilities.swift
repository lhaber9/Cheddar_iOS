//
//  Utilities.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/26/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Crashlytics

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
    
    class func formatDate(date: NSDate, withTrailingHours: Bool) -> String {
        let dateFor: NSDateFormatter = NSDateFormatter()
        
        let midnight = NSCalendar.currentCalendar().startOfDayForDate(NSDate())
        let sixHoursAgo = NSDate().dateByAddingTimeInterval(-1 * 6 * 3600)  // 6hours 3600seconds
        if (midnight.compare(date) == NSComparisonResult.OrderedAscending ||
            sixHoursAgo.compare(date) == NSComparisonResult.OrderedAscending) {
            dateFor.dateFormat = "h:mm a"
        }
        else {
            let threeDaysAgo = NSDate().dateByAddingTimeInterval(-1 * 3 * 24 * 3600) // 3days 24hours 3600seconds
            if (threeDaysAgo.compare(date) == NSComparisonResult.OrderedAscending) {
                if (withTrailingHours) {
                    dateFor.dateFormat = "EEE, h:mm a"
                }
                else {
                    dateFor.dateFormat = "EEE"
                }
            }
            else {
                if (withTrailingHours) {
                    dateFor.dateFormat = "MMM d, h:mm a"
                }
                else {
                    dateFor.dateFormat = "MMM d"
                }
                
            }
        }

        return dateFor.stringFromDate(date)
    }
    
    class func formattedLastMessageText(chatEvent: ChatEvent) -> String {
        var lastMessageText: String = ""
        if (chatEvent.type == ChatEventType.Message.rawValue) {
            lastMessageText = chatEvent.alias.name + ": "
        }
        
        lastMessageText = lastMessageText + chatEvent.body
        
        if (chatEvent.type == ChatEventType.NameChange.rawValue) {
            lastMessageText = lastMessageText.substringToIndex(lastMessageText.endIndex.advancedBy((chatEvent.roomName.characters.count + 4) * -1)) // +4 for _to_ text
        }

        return lastMessageText
    }
    
    class func sendAnswersEvent(eventName: String, alias:Alias, attributes:[String:AnyObject]) {
        
        var mutableAttrs = attributes
        mutableAttrs["aliasId"] = alias.objectId
        mutableAttrs["chatRoomId"] = alias.chatRoomId
        
        Answers.logCustomEventWithName(eventName, customAttributes: mutableAttrs)
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