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
    case NameChange = "CHANGE_ROOM_NAME"
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
    @NSManaged var roomName: String!
    
    class func removeAll() {
        let chatEvents = fetchAll()
        for chatEvent in chatEvents {
            Utilities.appDelegate().managedObjectContext.deleteObject(chatEvent)
        }
        Utilities.appDelegate().saveContext()
    }
    
    class func newChatEvent() -> ChatEvent {
        let ent =  NSEntityDescription.entityForName("ChatEvent", inManagedObjectContext: Utilities.appDelegate().managedObjectContext)!
        let chatevent = ChatEvent(entity: ent, insertIntoManagedObjectContext: Utilities.appDelegate().managedObjectContext)
        chatevent.messageId = NSUUID.init().UUIDString
        return chatevent
    }
    
    class func createOrRetrieve(objectId:String, type:ChatEventType) -> ChatEvent! {
        
        var chatEvent: ChatEvent!
        chatEvent = fetchById(objectId)
        
        if (chatEvent == nil) {
            return newChatEvent()
        }
        return chatEvent
    }
    
    class func createOrUpdateEventFromParseObject(object: PFObject) -> ChatEvent! {
        
        let objectId = object.objectId
        var chatEvent: ChatEvent!
        
        if let type = object.objectForKey("type") as? String {
            if (type == ChatEventType.Message.rawValue) {
                if let messageId = object.objectForKey("messageId") as? String {
                    chatEvent = ChatEvent.fetchByMessageId(messageId)
                }
            }
            
            if (chatEvent == nil) {
                chatEvent = ChatEvent.createOrRetrieve(objectId!, type: ChatEventType(rawValue:type)!)
            }
        }
        else {
            return nil
        }
        
        chatEvent.objectId = object.objectId
        chatEvent.messageId = object.objectForKey("messageId") as? String
        chatEvent.body = object.objectForKey("body") as? String
        chatEvent.type = object.objectForKey("type") as? String
        chatEvent.roomName = object.objectForKey("roomName") as? String
        
        chatEvent.createdAt = object.createdAt
        chatEvent.updatedAt = object.updatedAt
        
        if let aliasObject = object.objectForKey("alias") as? PFObject {
            chatEvent.alias = Alias.fetchById(aliasObject.objectId!)
        }
        
        chatEvent.status = ChatEventStatus.Success.rawValue
        
        return chatEvent
    }
    
    class func createOrUpdateEventFromServerJSON(jsonMessage: [NSObject: AnyObject]) -> ChatEvent! {
        
        let objectId = jsonMessage["objectId"] as! String
        var chatEvent: ChatEvent!
        
        if let type = jsonMessage["type"] as? String {
            if (type == ChatEventType.Message.rawValue) {
                if let messageId = jsonMessage["messageId"] as? String {
                    chatEvent = ChatEvent.fetchByMessageId(messageId)
                }
            }
        
            if (chatEvent == nil) {
                chatEvent = ChatEvent.createOrRetrieve(objectId, type: ChatEventType(rawValue:type)!)
            }
        }
        else {
            return nil
        }
        
        chatEvent.objectId = jsonMessage["objectId"] as? String
        chatEvent.messageId = jsonMessage["messageId"] as? String
        chatEvent.body = jsonMessage["body"] as? String
        chatEvent.type = jsonMessage["type"] as? String
        chatEvent.roomName = jsonMessage["roomName"] as? String
        
        let dateFor: NSDateFormatter = NSDateFormatter()
        dateFor.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let updatedAt = jsonMessage["updatedAt"] as? String {
            chatEvent.updatedAt = dateFor.dateFromString(updatedAt)
        }
        if let createdAt = jsonMessage["createdAt"] as? String {
            chatEvent.createdAt = dateFor.dateFromString(createdAt)
        }
        
        if let aliasDict = jsonMessage["alias"] as? [String: AnyObject] {
            chatEvent.alias = Alias.fetchById(aliasDict["objectId"] as! String)
        }
        else if let aliasObject = jsonMessage["alias"] as? PFObject {
            chatEvent.alias = Alias.fetchById(aliasObject.objectId!)
        }
        
        chatEvent.status = ChatEventStatus.Success.rawValue
        return chatEvent
    }
    
    class func isNewEvent(objectId:String, messageId:String) -> Bool {
        if (ChatEvent.fetchByMessageId(messageId) == nil &&
            ChatEvent.fetchById(objectId) == nil) {
            return true
        }
        
        return false
    }
    
    class func fetchAll() -> [ChatEvent] {
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest(entityName: "ChatEvent")
        
        do {
            return try moc.executeFetchRequest(dataFetch) as! [ChatEvent]
        } catch {
            return []
        }
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
    
    class func fetchByMessageId(messageId:String) -> ChatEvent! {
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest(entityName: "ChatEvent")
        dataFetch.predicate = NSPredicate(format: "messageId == %@", messageId)
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