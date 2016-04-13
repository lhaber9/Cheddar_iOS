//
//  ChatRoom.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/21/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import CoreData
import Parse
import Crashlytics

protocol ChatRoomDelegate: class {
    func didUpdateEvents(chatRoom:ChatRoom)
    func didAddEvent(chatRoom:ChatRoom, isMine: Bool)
    func didUpdateActiveAliases(chatRoom:ChatRoom, aliases:NSSet)
    func didReloadEvents(chatRoom:ChatRoom, eventCount:Int, firstLoad: Bool)
}

class ChatRoom: NSManagedObject {
    
    weak var delegate: ChatRoomDelegate?
    
    @NSManaged var objectId: String
    @NSManaged var maxOccupants: Int
    @NSManaged var numOccupants: Int
    
    @NSManaged var myAlias: Alias!
    @NSManaged var activeAliases: Set<Alias>!
    
    @NSManaged var chatEvents: Set<ChatEvent>!
    
    @NSManaged func addChatEventsObject(value:ChatEvent)
    @NSManaged func removeChatEventsObject(value:ChatEvent)
    @NSManaged func addChatEvents(value:Set<ChatEvent>)
    @NSManaged func removeChatEvents(value:Set<ChatEvent>)
    
    @NSManaged func addActiveAliasesObject(value:Alias)
    @NSManaged func removeActiveAliasesObject(value:Alias)
    @NSManaged func addActiveAliases(value:Set<Alias>)
    @NSManaged func removeActiveAliases(value:Set<Alias>)
    
    @NSManaged var currentStartToken: String!
    @NSManaged var allMessagesLoaded: NSNumber!

    var loadMessageCallInFlight = false
    
    class func newChatRoom() -> ChatRoom {
        let ent =  NSEntityDescription.entityForName("ChatRoom", inManagedObjectContext: Utilities.appDelegate().managedObjectContext)!
        let chatRoom = ChatRoom(entity: ent, insertIntoManagedObjectContext: Utilities.appDelegate().managedObjectContext)
        chatRoom.currentStartToken = nil
        chatRoom.allMessagesLoaded = false
        return chatRoom
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
    
    class func fetchFirstRoom() -> ChatRoom! {
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
            let results = (try moc.executeFetchRequest(dataFetch) as! [ChatRoom])
            if (results.count > 0) {
                return results[0]
            }
            return nil
        } catch {
            return nil
        }
    }
    
    func reload() {
        reloadActiveAlaises()
        reloadMessages()
    }
    
    func sortedChatEvents() -> [ChatEvent] {
        return chatEvents.sort({ (event1: ChatEvent, event2: ChatEvent) -> Bool in
            if (event1.createdAt.compare(event2.createdAt) == NSComparisonResult.OrderedAscending){
                return true
            }
            return false
        })
    }
    
    func reloadActiveAlaises() {
        PFCloud.callFunctionInBackground("getActiveAliases", withParameters: ["chatRoomId":myAlias.chatRoomId]) { (objects: AnyObject?, error: NSError?) -> Void in
            
            if (error != nil) {
                NSLog("error: %@", error!)
                return
            }
            
            var activeAliases = Set<Alias>()
            
            for alias in objects as! [PFObject] {
                activeAliases.insert(Alias.createOrUpdateAliasFromParseObject(alias, isTemporary: false))
            }
            
            if (self.activeAliases != nil) {
                 self.removeActiveAliases(self.activeAliases)
            }
            self.addActiveAliases(activeAliases)
            
            Utilities.appDelegate().saveContext()
            
            self.delegate?.didUpdateActiveAliases(self, aliases: activeAliases)
        }
    }
    
    func isMyChatEvent(event: ChatEvent) -> Bool {
        return (event.alias.objectId == myAlias.objectId)
    }
    
    func sendMessage(message: ChatEvent) {
        addChatEvent(message)
        Utilities.appDelegate().sendMessage(message)
    }
    
    func addChatEvent(event: ChatEvent) {
        chatEvents.insert(event)
        Utilities.appDelegate().saveContext()
        self.delegate?.didAddEvent(self, isMine: isMyChatEvent(event))
    }
    
    func findFirstMessageBeforeIndex(index: Int) -> ChatEvent! {
        var position = index - 1
        if (position < 0) {
            return nil
        }
        
        var message = sortedChatEvents()[position]
        while (message.type != ChatEventType.Message.rawValue) {
            position -= 1
            if (position < 0) { return nil }
            message = sortedChatEvents()[position]
        }
        return message
    }

    func findFirstMessageAfterIndex(index: Int) -> ChatEvent! {
        var position = index + 1
        if (position >= chatEvents.count) {
            return nil
        }
        
        var message = sortedChatEvents()[position]
        while (message.type != ChatEventType.Message.rawValue) {
            position += 1
            if (position >= chatEvents.count) { return nil }
            message = sortedChatEvents()[position]
        }
        return message
    }
    
    func reloadMessages() {
        if (currentStartToken == nil || loadMessageCallInFlight) {
            return
        }
        
        loadMessageCallInFlight = true
        
        let params: [NSObject:AnyObject] = ["aliasId": myAlias.objectId!,
                                            "subkey":EnvironmentConstants.pubNubSubscribeKey,
                                            "endTimeToken" : currentStartToken]
        
        PFCloud.callFunctionInBackground("replayEvents", withParameters: params) { (object: AnyObject?, error: NSError?) -> Void in

            var replayEvents = Set<ChatEvent>()
            
            if let events = object?["events"] as? [[NSObject:AnyObject]] {

                for eventDict in events {
                    
                    let objectType = eventDict["objectType"] as! String
                    let objectDict = eventDict["object"] as! [NSObject:AnyObject]
                    
                    if (objectType == "ChatEvent") {
                        replayEvents.insert(ChatEvent.createOrUpdateEventFromServerJSON(objectDict as! [String:AnyObject]))
                    }
                }

                if (self.chatEvents != nil) {
                    self.removeChatEvents(self.chatEvents)
                }
                self.addChatEvents(replayEvents)
                
                Utilities.appDelegate().saveContext()
                
                self.delegate?.didUpdateEvents(self)
            }
            
            self.loadMessageCallInFlight = false
        }
    }
    
    func loadNextPageMessages() {
        
        if (allMessagesLoaded.boolValue || loadMessageCallInFlight) {
            return
        }
        
        let count = 25
        
        var params: [NSObject:AnyObject] = ["count":count, "aliasId": myAlias.objectId!, "subkey":EnvironmentConstants.pubNubSubscribeKey]
        if (currentStartToken != nil) {
            params["startTimeToken"] = currentStartToken
        }
        
        loadMessageCallInFlight = true
        PFCloud.callFunctionInBackground("replayEvents", withParameters: params) { (object: AnyObject?, error: NSError?) -> Void in
            
            if let startToken = object?["startTimeToken"] as? String {
                self.currentStartToken = startToken
            }
            
            if let events = object?["events"] as? [[NSObject:AnyObject]] {
                
                if (events.count < count) {
                    self.allMessagesLoaded = true
                }
                
                if (events.count == 1 && self.chatEvents.count == 1) {
                    self.loadMessageCallInFlight = false
                    return
                }
                
                for eventDict in events {
                    
                    let objectType = eventDict["objectType"] as! String
                    let objectDict = eventDict["object"] as! [NSObject:AnyObject]
                    
                    if (objectType == "ChatEvent") {
                        self.chatEvents.insert(ChatEvent.createOrUpdateEventFromServerJSON(objectDict as! [String:AnyObject]))
                    }
                }
                
                var isFirstLoad = false
                if (self.chatEvents.count == 0) {
                    isFirstLoad = true
                }
                
                Utilities.appDelegate().saveContext()
                
                self.delegate?.didReloadEvents(self, eventCount: events.count, firstLoad: isFirstLoad)
            }
            
            self.loadMessageCallInFlight = false
        }
    }
    
    func shouldShowAliasLabelForMessageIndex(messageIdx: Int) -> Bool {
        let event = sortedChatEvents()[messageIdx]
        if (event.type == ChatEventType.Message.rawValue) {
            let messageBefore = findFirstMessageBeforeIndex(messageIdx)
            if (messageBefore != nil) {
                return messageBefore.alias.objectId != event.alias.objectId
            }
            else {
                return true
            }
        }
        
        return false
    }
    
    func shouldShowAliasIconForMessageIndex(messageIdx: Int) -> Bool {
        let event = sortedChatEvents()[messageIdx]
        if (event.type == ChatEventType.Message.rawValue) {
            let messageAfter = findFirstMessageAfterIndex(messageIdx)
            if (messageAfter != nil) {
                return messageAfter.alias.objectId != event.alias.objectId
            }
            else {
                return true
            }
        }
        
        return false
    }
    
}