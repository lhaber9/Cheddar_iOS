//
//  ChatEvent.swift
//  Cheddar
//
//  Created by Lucas Haber on 4/11/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import CoreData
import Parse

enum ChatEventStatus:String {
    case Sent = "Sent"
    case Success = "Success"
    case Error = "Error"
}

enum ChatEventType:String {
    case Message = "MESSAGE"
    case Presence = "PRESENCE"
}

class ChatEvent: NSManagedObject {
    
    @NSManaged var objectId: String!
    @NSManaged var messageId: String!
    @NSManaged var body: String!
    @NSManaged var type: String!
    @NSManaged var alias: Alias!
    @NSManaged var createdAt: NSDate!
    @NSManaged var updatedAt: NSDate!
    @NSManaged var status: String!
    
    class func newChatEvent() -> ChatEvent {
        let ent =  NSEntityDescription.entityForName("ChatEvent", inManagedObjectContext: Utilities.appDelegate().managedObjectContext)!
        let chatevent = ChatEvent(entity: ent, insertIntoManagedObjectContext: Utilities.appDelegate().managedObjectContext)
        chatevent.messageId = NSUUID.init().UUIDString
        return chatevent
    }
    
    class func createOrRetrieve(objectId:String, type:ChatEventType) -> ChatEvent! {
        
        var chatEvent: ChatEvent!
        if (type == ChatEventType.Message) {
            chatEvent = fetchByChatEventId(objectId)
        }
        else if (type == ChatEventType.Presence) {
            chatEvent = fetchById(objectId)
        }
        
        if (chatEvent == nil) {
            return newChatEvent()
        }
        return chatEvent
    }
    
    class func createOrUpdateEventFromServerJSON(jsonMessage: [String: AnyObject]) -> ChatEvent! {
        
        var id = jsonMessage["objectId"] as! String
        var newChatEvent: ChatEvent
        
        if let type = jsonMessage["type"] as? String {
            if (type == ChatEventType.Message.rawValue) {
                if let messageId = jsonMessage["messageId"] as? String {
                    id = messageId
                }
            }
            newChatEvent = ChatEvent.createOrRetrieve(id, type: ChatEventType(rawValue:type)!)
        }
        else {
            return nil
        }
        
        for (key, value) in jsonMessage {
            if (key == "alias") {
                if let aliasDict = value as? [String: AnyObject] {
                    newChatEvent.alias = Alias.createOrUpdateAliasFromJson(aliasDict, isTemporary: false)
                }
                else if let aliasObject = value as? PFObject {
                    newChatEvent.alias = Alias.createOrUpdateAliasFromParseObject(aliasObject, isTemporary: false)
                }
            }
            else if (key == "updatedAt" || key == "createdAt") {
                let dateFormatter = NSDateFormatter()
                
                //Specify Format of String to Parse
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                
                //Parse into NSDate
                let dateFromString : NSDate = dateFormatter.dateFromString(value as! String)!
                
                newChatEvent.setValue(dateFromString, forKey: key)
            }
            else {
                newChatEvent.setValue(value, forKey: key)
            }
        }
        
        newChatEvent.status = ChatEventStatus.Success.rawValue
        
        return newChatEvent
    }
    
    class func fetchById(eventId:String) -> ChatEvent! {
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest(entityName: "ChatEvent")
        dataFetch.predicate = NSPredicate(format: "objectId == %@", eventId)
        do {
            let results = (try moc.executeFetchRequest(dataFetch) as! [ChatEvent])
            if (results.count > 0) {
                return results[0]
            }
            return nil
        } catch {
            return nil
        }
    }
    
    class func fetchByChatEventId(eventId:String) -> ChatEvent! {
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest(entityName: "ChatEvent")
        dataFetch.predicate = NSPredicate(format: "messageId == %@", eventId)
        do {
            let results = (try moc.executeFetchRequest(dataFetch) as! [ChatEvent])
            if (results.count > 0) {
                return results[0]
            }
            return nil
        } catch {
            return nil
        }
    }
    
//    class func createEventFromParseObject(eventObject: PFObject) -> ChatEvent {
//        let newChatEvent = ChatEvent.createOrRetrieve(eventObject.objectId!)
//        
//        for (key, value) in jsonMessage {
//            if (key == "alias") {
//                newChatEvent.alias = Alias.createAliasFromJson(value as! [NSObject : AnyObject], isTemporary: false)
//            }
//            else if (key == "updatedAt" || key == "createdAt") {
//                let dateFormatter = NSDateFormatter()
//                
//                //Specify Format of String to Parse
//                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
//                
//                //Parse into NSDate
//                let dateFromString : NSDate = dateFormatter.dateFromString(value as! String)!
//                
//                newChatEvent.setValue(dateFromString, forKey: key)
//            }
//            else {
//                newChatEvent.setValue(value, forKey: key)
//            }
//        }
//        
//        newChatEvent.status = ChatEventStatus.Success.rawValue
//        
//        return newChatEvent
//    }

    
    class func createEvent(body: String, alias: Alias, createdAt: NSDate!, type:String, status:ChatEventStatus!) -> ChatEvent {
        let newChatEvent = ChatEvent.newChatEvent()
        newChatEvent.body = body
        newChatEvent.alias = alias
        newChatEvent.createdAt = createdAt
        newChatEvent.type = type
        newChatEvent.status = status.rawValue
        
        if (status == nil) {
            newChatEvent.status = ChatEventStatus.Success.rawValue
        }
        
        return newChatEvent
    }
}