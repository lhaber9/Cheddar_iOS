//
//  Message.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/10/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import PubNub

class Message: NSObject {

    var messageText: String = ""
    var fromUserId: String = ""
    var channel: String = ""
    
    
    func toJson() -> String {
        
        var jsonString = "{"
        
        jsonString += "\"messageText\":\"" + messageText + "\","
        jsonString +=  "\"fromUserId\":\"" + fromUserId + "\","
        jsonString +=  "\"channel\":\"" + channel + "\"}"
        
        return jsonString
    }
    
    class func createMessage(jsonMessage: [NSObject: AnyObject]) -> Message {
        let newMessage = Message()
        
        if let text = jsonMessage["messageText"] as? String {
            newMessage.messageText = text
        }
        if let userId = jsonMessage["fromUserId"] as? String {
            newMessage.fromUserId = userId
        }
        if let channel = jsonMessage["channel"] as? String {
            newMessage.channel = channel
        }
        
        return newMessage
    }
    
    class func createMessage(text: String, userId: String, channel: String) -> Message {
        let newMessage = Message()
        newMessage.messageText = text
        newMessage.fromUserId = userId
        newMessage.channel = channel
    
        return newMessage
    }
    
}