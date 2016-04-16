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
    @NSManaged var colorId: Int
    
    var leftAt: NSDate!
    
    class func newAlias(isTemporary: Bool) -> Alias {
        let ent =  NSEntityDescription.entityForName("Alias", inManagedObjectContext: Utilities.appDelegate().managedObjectContext)!
        
        var context: NSManagedObjectContext! = nil
        if (!isTemporary) {
            context = Utilities.appDelegate().managedObjectContext
        }
        
        return Alias(entity: ent, insertIntoManagedObjectContext: context)
    }
    
    class func createOrRetrieve(objectId:String, isTemporary: Bool) -> Alias! {
        let alias = fetchById(objectId)
        if (alias == nil) {
            return newAlias(isTemporary)
        }
        return alias
    }
    
    class func newTempAlias() -> Alias {
        let ent =  NSEntityDescription.entityForName("Alias", inManagedObjectContext: Utilities.appDelegate().managedObjectContext)!
        return Alias(entity: ent, insertIntoManagedObjectContext: nil)
    }
    
    class func createOrUpdateAliasFromJson(jsonMessage: [NSObject: AnyObject], isTemporary:Bool) -> Alias {
        let objectId = jsonMessage["objectId"] as? String
        
        let newAlias = Alias.createOrRetrieve(objectId!, isTemporary: isTemporary)
        newAlias.objectId = objectId
        
        if let chatRoomId = jsonMessage["chatRoomId"] as? String {
            newAlias.chatRoomId = chatRoomId
        }
        if let name = jsonMessage["name"] as? String {
            newAlias.name = name.capitalizedString
        }
        if let userId = jsonMessage["userId"] as? String {
            newAlias.userId = userId
        }
        if let colorId = jsonMessage["colorId"] as? Int {
            newAlias.colorId = colorId
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
    
    class func createOrUpdateAliasFromParseObject(pfObject: PFObject, isTemporary:Bool) -> Alias {
        let newAlias = Alias.createOrRetrieve(pfObject.objectId!, isTemporary: isTemporary)
        newAlias.objectId = pfObject.objectId!
        
        if let chatRoomId = pfObject.objectForKey("chatRoomId") as? String {
            newAlias.chatRoomId = chatRoomId
        }
        if let name = pfObject.objectForKey("name") as? String {
            newAlias.name = name.capitalizedString
        }
        if let userId = pfObject.objectForKey("userId") as? String {
            newAlias.userId = userId
        }
        if let leftAt = pfObject.objectForKey("leftAt") as? NSDate {
            newAlias.leftAt = leftAt
        }
        if let colorId = pfObject.objectForKey("colorId") as? Int {
            newAlias.colorId = colorId
        }
        
        newAlias.joinedAt = pfObject.createdAt
        
        return newAlias
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