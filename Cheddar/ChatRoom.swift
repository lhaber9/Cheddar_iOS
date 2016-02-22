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
    @NSManaged var messages: NSArray
    
    var maxMessagesStored = 100
    
    class func newChatRoom() -> ChatRoom {
        let ent =  NSEntityDescription.entityForName("ChatRoom", inManagedObjectContext: (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext)!
        return ChatRoom(entity: ent, insertIntoManagedObjectContext: (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext)
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
        
        newRoom.objectId = alias.chatRoomId!
        newRoom.myAlias = alias
        
        return newRoom
    }
    
    class func fetchAll() -> [ChatRoom] {
        let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        let dataFetch = NSFetchRequest(entityName: "ChatRoom")
        
        do {
            return try moc.executeFetchRequest(dataFetch) as! [ChatRoom]
        } catch {
            return []
        }
    }
    
    func addMessages(newMessages: [Message]) {
        messages = messages.arrayByAddingObjectsFromArray(newMessages)
        (UIApplication.sharedApplication().delegate as! AppDelegate).saveContext()
    }
}