//
//  ChatEvent.swift
//  Cheddar
//
//  Created by Lucas Haber on 4/11/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import CoreData
//import Parse

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
    @NSManaged var createdAt: Date!
    @NSManaged var updatedAt: Date!
    @NSManaged var status: String!
    @NSManaged var roomName: String!
    
    class func removeAll() {
        let chatEvents = fetchAll()
        for chatEvent in chatEvents {
            Utilities.appDelegate().managedObjectContext.delete(chatEvent)
        }
        Utilities.appDelegate().saveContext()
    }
    
    class func newChatEvent() -> ChatEvent {
        let ent =  NSEntityDescription.entity(forEntityName: "ChatEvent", in: Utilities.appDelegate().managedObjectContext)!
        let chatevent = ChatEvent(entity: ent, insertInto: Utilities.appDelegate().managedObjectContext)
        chatevent.messageId = UUID.init().uuidString
        return chatevent
    }
    
    class func createOrRetrieve(_ objectId:String, type:ChatEventType) -> ChatEvent! {
        
        var chatEvent: ChatEvent!
        chatEvent = fetchById(objectId)
        
        if (chatEvent == nil) {
            return newChatEvent()
        }
        return chatEvent
    }
    
    class func createOrUpdateEventFromParseObject(_ object: PFObject) -> ChatEvent! {
        
        let objectId = object.objectId
        var chatEvent: ChatEvent!
        
        if let type = object.object(forKey: "type") as? String {
            if (type == ChatEventType.Message.rawValue) {
                if let messageId = object.object(forKey: "messageId") as? String {
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
        chatEvent.messageId = object.object(forKey: "messageId") as? String
        chatEvent.body = object.object(forKey: "body") as? String
        chatEvent.type = object.object(forKey: "type") as? String
        chatEvent.roomName = object.object(forKey: "roomName") as? String
        
        chatEvent.createdAt = object.createdAt
        chatEvent.updatedAt = object.updatedAt
        
        if let aliasObject = object.object(forKey: "alias") as? PFObject {
            chatEvent.alias = Alias.createOrUpdateAliasFromParseObject(aliasObject)
        }
        
        chatEvent.status = ChatEventStatus.Success.rawValue
        
        return chatEvent
    }
    
    class func createOrUpdateEventFromServerJSON(_ jsonMessage: NSDictionary) -> ChatEvent! {
        
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
        
        let dateFor: DateFormatter = DateFormatter()
        dateFor.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let updatedAt = jsonMessage["updatedAt"] as? String {
            chatEvent.updatedAt = dateFor.date(from: updatedAt)
        }
        if let createdAt = jsonMessage["createdAt"] as? String {
            chatEvent.createdAt = dateFor.date(from: createdAt)
        }
        
        if let aliasDict = jsonMessage["alias"] as? NSDictionary {
            chatEvent.alias = Alias.createOrUpdateAliasFromJson(aliasDict)
        }
        else if let aliasObject = jsonMessage["alias"] as? PFObject {
            chatEvent.alias = Alias.createOrUpdateAliasFromParseObject(aliasObject)
        }
        
        chatEvent.status = ChatEventStatus.Success.rawValue
        return chatEvent
    }
    
    class func isNewEvent(_ objectId:String, messageId:String) -> Bool {
        if (ChatEvent.fetchByMessageId(messageId) == nil &&
            ChatEvent.fetchById(objectId) == nil) {
            return true
        }
        
        return false
    }
    
    class func fetchAll() -> [ChatEvent] {
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatEvent")
        
        do {
            return try moc.fetch(dataFetch) as! [ChatEvent]
        } catch {
            return []
        }
    }
    
    class func fetchById(_ eventId:String) -> ChatEvent! {
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatEvent")
        dataFetch.predicate = NSPredicate(format: "objectId == %@", eventId)
        do {
            let results = (try moc.fetch(dataFetch) as! [ChatEvent])
            if (results.count > 0) {
                return results[0]
            }
            return nil
        } catch {
            return nil
        }
    }
    
    class func fetchByMessageId(_ messageId:String) -> ChatEvent! {
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatEvent")
        dataFetch.predicate = NSPredicate(format: "messageId == %@", messageId)
        do {
            let results = (try moc.fetch(dataFetch) as! [ChatEvent])
            if (results.count > 0) {
                return results[0]
            }
            return nil
        } catch {
            return nil
        }
    }
    
    class func createEvent(_ body: String, alias: Alias, createdAt: Date!, type:String, status:ChatEventStatus!) -> ChatEvent {
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
