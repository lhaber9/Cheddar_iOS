//
//  Alias.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/21/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
//import Parse
import CoreData

class Alias: NSManagedObject {
    
    @NSManaged var objectId: String!
    @NSManaged var userId: String!
    @NSManaged var chatRoomId: String!
    @NSManaged var name: String!
    @NSManaged var joinedAt: Date!
    @NSManaged var colorId: NSNumber!
    @NSManaged var deletedChatEventIds:AnyObject!
    
    var leftAt: Date!
    
    class func removeAll() {
        let aliases = fetchAll()
        for alias in aliases {
            Utilities.appDelegate().managedObjectContext.delete(alias)
        }
        Utilities.appDelegate().saveContext()
    }
    
    class func newAlias() -> Alias {
        let ent =  NSEntityDescription.entity(forEntityName: "Alias", in: Utilities.appDelegate().managedObjectContext)!
        
        var context: NSManagedObjectContext! = nil
        context = Utilities.appDelegate().managedObjectContext
        
        return Alias(entity: ent, insertInto: context)
    }
    
    class func createOrRetrieve(_ objectId:String) -> Alias! {
        let alias = fetchById(objectId)
        if (alias == nil) {
            return newAlias()
        }
        return alias
    }
    
    class func newTempAlias() -> Alias {
        let ent =  NSEntityDescription.entity(forEntityName: "Alias", in: Utilities.appDelegate().managedObjectContext)!
        return Alias(entity: ent, insertInto: nil)
    }
    
    class func createOrUpdateAliasFromJson(_ jsonMessage: NSDictionary) -> Alias {
        
        let objectId = jsonMessage["objectId"] as? String
        let newAlias = Alias.createOrRetrieve(objectId!)!
        
        newAlias.objectId = objectId
        newAlias.chatRoomId = jsonMessage["chatRoomId"] as? String
        newAlias.name = jsonMessage["name"] as? String
        newAlias.userId = jsonMessage["userId"] as? String
        newAlias.colorId = jsonMessage["colorId"] as? NSNumber
        
        if let deletedChatEventIds = jsonMessage["deletedChatEventIds"] {
            newAlias.deletedChatEventIds = deletedChatEventIds as AnyObject 
        }
        
        let dateFor: DateFormatter = DateFormatter()
        dateFor.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let leftAt = jsonMessage["leftAt"] as? String {
            newAlias.leftAt = dateFor.date(from: leftAt)
        }
        if let joinedAt = jsonMessage["createdAt"] as? String {
            newAlias.joinedAt = dateFor.date(from: joinedAt)
        }
        
        return newAlias
    }
    
    class func createOrUpdateAliasFromParseObject(_ pfObject: PFObject) -> Alias {
        let newAlias = Alias.createOrRetrieve(pfObject.objectId!)
        newAlias?.objectId = pfObject.objectId!
        
        newAlias?.chatRoomId = pfObject.object(forKey: "chatRoomId") as? String
        newAlias?.name = pfObject.object(forKey: "name") as? String
        newAlias?.userId = pfObject.object(forKey: "userId") as? String
        newAlias?.leftAt = pfObject.object(forKey: "leftAt") as? Date
        newAlias?.colorId = pfObject.object(forKey: "colorId") as? NSNumber
        newAlias?.joinedAt = pfObject.createdAt
        
        if let deletedChatEventIds = pfObject.object(forKey: "deletedChatEventIds") {
            newAlias?.deletedChatEventIds = deletedChatEventIds as AnyObject
        }
        
        return newAlias!
    }
    
    class func fetchAll() -> [Alias] {
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Alias")
        
        do {
            return try moc.fetch(dataFetch) as! [Alias]
        } catch {
            return []
        }
    }
    
    class func fetchById(_ aliasId:String) -> Alias! {
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Alias")
        dataFetch.predicate = NSPredicate(format: "objectId == %@", aliasId)
        do {
            let results = (try moc.fetch(dataFetch) as! [Alias])
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
        let nameArray = name!.components(separatedBy: CharacterSet(charactersIn: " "))
        initals.append((nameArray[0].capitalized.characters.first)!)
        initals.append((nameArray[1].capitalized.characters.first)!)
        
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
