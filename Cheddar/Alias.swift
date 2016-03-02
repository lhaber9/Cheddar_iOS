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
    
    @NSManaged var objectId: String!
    @NSManaged var userId: String!
    @NSManaged var chatRoomId: String!
    @NSManaged var name: String!
    
    var leftAt: NSDate!
    var joinedAt: NSDate!

    class func newAlias(isTemporary: Bool) -> Alias {
        let ent =  NSEntityDescription.entityForName("Alias", inManagedObjectContext: Utilities.appDelegate().managedObjectContext)!
        
        var context: NSManagedObjectContext! = nil
        if (!isTemporary) {
            context = Utilities.appDelegate().managedObjectContext
        }
        
        return Alias(entity: ent, insertIntoManagedObjectContext: context)
    }
    
    class func newTempAlias() -> Alias {
        let ent =  NSEntityDescription.entityForName("Alias", inManagedObjectContext: Utilities.appDelegate().managedObjectContext)!
        return Alias(entity: ent, insertIntoManagedObjectContext: nil)
    }
    
    class func createAliasFromJson(jsonMessage: [NSObject: AnyObject], isTemporary:Bool) -> Alias {
        let newAlias = Alias.newAlias(isTemporary)
        
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
        
        let dateFor: NSDateFormatter = NSDateFormatter()
        dateFor.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let leftAt = jsonMessage["leftAt"] as? String {
            newAlias.leftAt = dateFor.dateFromString(leftAt)
        }
        if let joinedAt = jsonMessage["createdAt"] as? String {
            newAlias.joinedAt = dateFor.dateFromString(joinedAt)
        }
        
        return newAlias
    }
    
    class func createAliasFromParseObject(pfObject: PFObject, isTemporary:Bool) -> Alias {
        let newAlias = Alias.newAlias(isTemporary)
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
        if let leftAt = pfObject.objectForKey("leftAt") as? NSDate {
            newAlias.leftAt = leftAt
        }
        
        newAlias.joinedAt = pfObject.createdAt
        
        return newAlias
    }
    
//    func toJsonDict() -> [NSObject:AnyObject] {
//        var jsonDict = [NSObject:AnyObject]()
//        
//        jsonDict["objectId"] = objectId
//        jsonDict["chatRoomId"] = chatRoomId
//        jsonDict["name"] = name
//        jsonDict["userId"] = userId
//        
//        return jsonDict
//    }
    
    func initials() -> String {
        
        var initals = ""
        let nameArray = name!.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: " "))
        initals.append((nameArray[0].capitalizedString.characters.first)!)
        initals.append((nameArray[1].capitalizedString.characters.first)!)
        
        return initals
    }
    
//    func managedObjectContext() -> NSManagedObjectContext? {
//        return Utilities.appDelegate().managedObjectContext
//    }
    
}