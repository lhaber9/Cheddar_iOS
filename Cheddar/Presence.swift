//
//  Presence.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/25/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation


class Presence {
    
    var alias: Alias!
    var action: String!
    var timestamp: Int!
    
    class func createPresenceEvent(jsonEvent: [NSObject: AnyObject]) -> Presence {
        let newPresenceEvent = Presence()
        
        if let timestamp = jsonEvent["timestamp"] as? Int {
            newPresenceEvent.timestamp = timestamp
        }
        if let aliasDict = jsonEvent["alias"] as? [NSObject:AnyObject] {
            newPresenceEvent.alias = Alias.createOrUpdateAliasFromJson(aliasDict, isTemporary: true)
        }
        if let action = jsonEvent["action"] as? String {
            newPresenceEvent.action = action
        }
        
        return newPresenceEvent
    }
    
    class func createPresenceEvent(timestamp: Int, action: String, aliasDict: [NSObject: AnyObject]) -> Presence {
        let newPresenceEvent = Presence()
        
        newPresenceEvent.timestamp = timestamp
        newPresenceEvent.action = action
        newPresenceEvent.alias = Alias.createOrUpdateAliasFromJson(aliasDict, isTemporary: true)
        
        return newPresenceEvent
    }

    
}