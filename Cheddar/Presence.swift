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
        if let aliasDict = jsonEvent["data"] as? [NSObject:AnyObject] {
            newPresenceEvent.alias = Alias.createAliasFromJson(aliasDict)
        }
        if let action = jsonEvent["action"] as? String {
            newPresenceEvent.action = action
        }
        
        return newPresenceEvent
    }
    
    class func createPresenceEvent(timestamp: Int, stateDict: [NSObject: AnyObject]) -> Presence {
        let newPresenceEvent = Presence()
        
        newPresenceEvent.timestamp = timestamp
        
        if let action = stateDict["action"] as? String {
            newPresenceEvent.action = action
        }
        if let aliasDict = stateDict["alias"] as? [NSObject:AnyObject] {
            newPresenceEvent.alias = Alias.createAliasFromJson(aliasDict)
        }
        
        return newPresenceEvent
    }

    
}