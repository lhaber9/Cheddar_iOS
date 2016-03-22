//
//  ChatRoom.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/21/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import CoreData

class ChatRoom: NSManagedObject {
    
    @NSManaged var objectId: String
    @NSManaged var maxOccupants: Int
    @NSManaged var numOccupants: Int
    
    @NSManaged var myAlias: Alias!
    
    class func newChatRoom() -> ChatRoom {
        let ent =  NSEntityDescription.entityForName("ChatRoom", inManagedObjectContext: Utilities.appDelegate().managedObjectContext)!
        return ChatRoom(entity: ent, insertIntoManagedObjectContext: Utilities.appDelegate().managedObjectContext)
    }
    
    class func createChatRoom(jsonMessage: [NSObject: AnyObject]) -> ChatRoom {
        let newRoom = ChatRoom.newChatRoom()
        
        if let objectId = jsonMessage["objectId"] as? String {
            newRoom.objectId = objectId
        }
        if let maxOccupants = jsonMessage["maxOccupants"] as? Int {
            newRoom.maxOccupants = maxOccupants
        }
        if let numOccupants = jsonMessage["numOccupants"] as? Int {
            newRoom.numOccupants = numOccupants
        }
        
        return newRoom
    }
    
    class func createWithMyAlias(alias: Alias) -> ChatRoom {
        let newRoom = ChatRoom.newChatRoom()
        
        newRoom.objectId = alias.chatRoomId
        newRoom.myAlias = alias
        
        return newRoom
    }
    
    class func fetchSingleRoom() -> ChatRoom! {
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest(entityName: "ChatRoom")
        do {
            let result = (try moc.executeFetchRequest(dataFetch) as! [ChatRoom])
            if (result.count > 0) {
                return result[0]
            }
            return nil
        } catch {
            return nil
        }

    }
    
    class func fetchAll() -> [ChatRoom] {
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest(entityName: "ChatRoom")
        
        do {
            return try moc.executeFetchRequest(dataFetch) as! [ChatRoom]
        } catch {
            return []
        }
    }

    class func fetchById(chatRoomId:String) -> ChatRoom! {
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest(entityName: "ChatRoom")
        dataFetch.predicate = NSPredicate(format: "objectId == %@", chatRoomId)
        
        do {
            return (try moc.executeFetchRequest(dataFetch) as! [ChatRoom])[0]
        } catch {
            return nil
        }
    }

//    class func addMessagesToRoom(newMessages: [Message], chatRoomId:String) {
//        let chatRoom = fetchById(chatRoomId)
//        chatRoom.addMessages(newMessages)
//    }
//
//    func addMessages(newMessages: [Message]) {
//        messages.appendContentsOf(newMessages)
//    }
//    
//    class func addPresenceEventsToRoom(newEvents: [Presence], chatRoomId:String) {
//        let chatRoom = fetchById(chatRoomId)
//        chatRoom.addPresenceEvents(newEvents)
//    }
}