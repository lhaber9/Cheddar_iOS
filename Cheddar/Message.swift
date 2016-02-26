//
//  Message.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/10/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

class Message {

    var body: String!
    var alias: Alias!
    var timestamp: Int!
    
    class func createMessage(jsonMessage: [NSObject: AnyObject]) -> Message {
        let newMessage = Message()
        
        if let body = jsonMessage["body"] as? String {
            newMessage.body = body
        }
        if let aliasDict = jsonMessage["alias"] as? [NSObject:AnyObject] {
            newMessage.alias = Alias.createAliasFromJson(aliasDict)
        }
        if let timestamp = jsonMessage["timestamp"] as? Int {
            newMessage.timestamp = timestamp
        }
        
        return newMessage
    }
    
    class func createMessage(body: String, alias: Alias, timestamp: Int!) -> Message {
        let newMessage = Message()
        newMessage.body = body
        newMessage.alias = alias
        newMessage.timestamp = timestamp
    
        return newMessage
    }
    
}