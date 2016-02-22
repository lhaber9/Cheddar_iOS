//
//  Alias.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/21/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Parse
import CoreData

class Alias: NSManagedObject {
    
    @NSManaged var objectId: String?
    @NSManaged var userId: String?
    @NSManaged var chatRoomId: String?
    @NSManaged var name: String?
    
    @NSManaged var chatRoom: ChatRoom?

    class func newAlias() -> Alias {
        let ent =  NSEntityDescription.entityForName("Alias", inManagedObjectContext: (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext)!
        return Alias(entity: ent, insertIntoManagedObjectContext: (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext)
    }
    
    class func createAliasFromJson(jsonMessage: [NSObject: AnyObject]) -> Alias {
        let newAlias = Alias.newAlias()
        
        if let objectId = jsonMessage["objectId"] as? String {
            newAlias.objectId = objectId
        }
        if let chatRoomId = jsonMessage["chatRoomId"] as? String {
            newAlias.chatRoomId = chatRoomId
        }
        if let name = jsonMessage["name"] as? String {
            newAlias.name = name
        }
        if let userId = jsonMessage["userId"] as? String {
            newAlias.userId = userId
        }
        
        return newAlias
    }
    
    class func createAliasFromParseObject(pfObject: PFObject) -> Alias {
        let newAlias = Alias.newAlias()
        newAlias.objectId = pfObject.objectId!
        
        if let chatRoomId = pfObject.objectForKey("chatRoomId") as? String {
            newAlias.chatRoomId = chatRoomId
        }
        if let name = pfObject.objectForKey("name") as? String {
            newAlias.name = name
        }
        if let userId = pfObject.objectForKey("userId") as? String {
            newAlias.userId = userId
        }
        
        return newAlias
    }
    
    func initials() -> String {
        
        var initals = ""
        let nameArray = name!.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: " "))
        initals.append((nameArray[0].capitalizedString.characters.first)!)
        initals.append((nameArray[1].capitalizedString.characters.first)!)
        
        return initals
    }
    
//    func managedObjectContext() -> NSManagedObjectContext? {
//        return (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
//    }
    
}