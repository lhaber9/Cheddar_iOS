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
    @NSManaged var joinedAt: NSDate!
    @NSManaged var colorId: NSNumber!
    @NSManaged var deletedChatEventIds:AnyObject!
    
    var leftAt: NSDate!
    
    class func removeAll() {
        let aliases = fetchAll()
        for alias in aliases {
            Utilities.appDelegate().managedObjectContext.deleteObject(alias)
        }
        Utilities.appDelegate().saveContext()
    }
    
    class func newAlias() -> Alias {
        let ent =  NSEntityDescription.entityForName("Alias", inManagedObjectContext: Utilities.appDelegate().managedObjectContext)!
        
        var context: NSManagedObjectContext! = nil
        context = Utilities.appDelegate().managedObjectContext
        
        return Alias(entity: ent, insertIntoManagedObjectContext: context)
    }
    
    class func createOrRetrieve(objectId:String) -> Alias! {
        let alias = fetchById(objectId)
        if (alias == nil) {
            return newAlias()
        }
        return alias
    }
    
    class func newTempAlias() -> Alias {
        let ent =  NSEntityDescription.entityForName("Alias", inManagedObjectContext: Utilities.appDelegate().managedObjectContext)!
        return Alias(entity: ent, insertIntoManagedObjectContext: nil)
    }
    
    class func createOrUpdateAliasFromJson(jsonMessage: [NSObject: AnyObject]) -> Alias {
        
        let objectId = jsonMessage["objectId"] as? String
        let newAlias = Alias.createOrRetrieve(objectId!)
        
        newAlias.objectId = objectId
        newAlias.chatRoomId = jsonMessage["chatRoomId"] as? String
        newAlias.name = jsonMessage["name"] as? String
        newAlias.userId = jsonMessage["userId"] as? String
        newAlias.colorId = jsonMessage["colorId"] as? NSNumber
        
        if let deletedChatEventIds = jsonMessage["deletedChatEventIds"] as? [String] {
            newAlias.deletedChatEventIds = deletedChatEventIds
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
    
    class func createOrUpdateAliasFromParseObject(pfObject: PFObject) -> Alias {
        let newAlias = Alias.createOrRetrieve(pfObject.objectId!)
        newAlias.objectId = pfObject.objectId!
        
        newAlias.chatRoomId = pfObject.objectForKey("chatRoomId") as? String
        newAlias.name = pfObject.objectForKey("name") as? String
        newAlias.userId = pfObject.objectForKey("userId") as? String
        newAlias.leftAt = pfObject.objectForKey("leftAt") as? NSDate
        newAlias.colorId = pfObject.objectForKey("colorId") as? NSNumber
        newAlias.joinedAt = pfObject.createdAt
        
        if let deletedChatEventIds = pfObject.objectForKey("deletedChatEventIds") as? [String] {
            newAlias.deletedChatEventIds = deletedChatEventIds
        }
        
        return newAlias
    }
    
    class func fetchAll() -> [Alias] {
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest(entityName: "Alias")
        
        do {
            return try moc.executeFetchRequest(dataFetch) as! [Alias]
        } catch {
            return []
        }
    }
    
    class func fetchById(aliasId:String) -> Alias! {
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest(entityName: "Alias")
        dataFetch.predicate = NSPredicate(format: "objectId == %@", aliasId)
        do {
            let results = (try moc.executeFetchRequest(dataFetch) as! [Alias])
            if (results.count > 0) {
                return results[0]
            }
            return nil
        } catch {
            return nil
        }
    }
    
    func deletedChatEventIdsArray() -> [String] {
        if let deletedIds = deletedChatEventIds as? [String] {
            return deletedIds
        }
        return []
    }
    
    func initials() -> String {
        
        var initals = ""
        let nameArray = name!.componentsSeparatedByCharactersInSet(NSCharacterSet(charactersInString: " "))
        initals.append((nameArray[0].capitalizedString.characters.first)!)
        initals.append((nameArray[1].capitalizedString.characters.first)!)
        
        return initals
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
}