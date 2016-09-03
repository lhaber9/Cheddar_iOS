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
    class func IS_IPHONE_4_OR_LESS() -> Bool { return IS_IPHONE() && (UIScreen.main.bounds.size.height < 568.0) }
    class func IS_IPHONE_5_OR_LESS() -> Bool { return IS_IPHONE_4_OR_LESS() || IS_IPHONE_5() }
    class func IS_IPHONE_5() -> Bool { return IS_IPHONE() && (UIScreen.main.bounds.size.height == 568.0) }
    class func IS_IPHONE_6() -> Bool { return IS_IPHONE() && (UIScreen.main.bounds.size.height == 667.0) }
    class func IS_IPHONE_6_PLUS() -> Bool { return IS_IPHONE() && (UIScreen.main.bounds.size.height == 736.0) }
    class func IS_IPAD() -> Bool { return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.pad) }
    class func IS_IPHONE() -> Bool { return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiom.phone) }
    
    class func appDelegate() -> AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    class func removeAllUserData() {
        for chatRoom in ChatRoom.fetchAll() {
            Utilities.appDelegate().unsubscribeFromPubNubChannel(chatRoom.objectId)
            Utilities.appDelegate().unsubscribeFromPubNubPushChannel(chatRoom.objectId)
        }
        
        ChatEvent.removeAll()
        ChatRoom.removeAll()
        Alias.removeAll()
    }
    
    class func envName() -> String {
        return Bundle.main.infoDictionary!["SchemeName"] as! String
    }
    
    class func formatDate(_ date: Date, withTrailingHours: Bool) -> String {
        let dateFor: DateFormatter = DateFormatter()
        
        let midnight = NSCalendar.current.startOfDay(for: Date())
        let sixHoursAgo = Date().addingTimeInterval(-1 * 6 * 3600)  // 6hours 3600seconds
        if (midnight.compare(date) == ComparisonResult.orderedAscending ||
            sixHoursAgo.compare(date) == ComparisonResult.orderedAscending) {
            dateFor.dateFormat = "h:mm a"
        }
        else {
            let threeDaysAgo = Date().addingTimeInterval(-1 * 3 * 24 * 3600) // 3days 24hours 3600seconds
            if (threeDaysAgo.compare(date) == ComparisonResult.orderedAscending) {
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

        return dateFor.string(from: date)
    }
    
    class func formattedLastMessageText(_ chatEvent: ChatEvent) -> String {
        var lastMessageText: String = ""
        if (chatEvent.type == ChatEventType.Message.rawValue) {
            lastMessageText = chatEvent.alias.name + ": "
        }
        
        lastMessageText = lastMessageText + chatEvent.body
        
        if (chatEvent.type == ChatEventType.NameChange.rawValue) {
            lastMessageText = lastMessageText.substring(to: lastMessageText.index(lastMessageText.endIndex, offsetBy: (chatEvent.roomName.characters.count + 4) * -1)) // +4 for _to_ text
        }

        return lastMessageText
    }
    
    class func sendAnswersEvent(_ eventName: String, alias:Alias, attributes:[String:AnyObject]) {
        
        var mutableAttrs = attributes
        mutableAttrs["aliasId"] = alias.objectId as AnyObject
        mutableAttrs["chatRoomId"] = alias.chatRoomId as AnyObject
        
        Answers.logCustomEvent(withName: eventName, customAttributes: mutableAttrs)
    }
    
    class func getKeyConstant(_ name: String) -> String! {
        var keys: NSDictionary?
        
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        if let dict = keys![envName()] as? NSDictionary {
            return (dict[name] as? String)!
        }
        return nil
    }
}
