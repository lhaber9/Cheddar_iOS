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
    func didUpdateEvents()
    func didUpdateActiveAliases(aliases:NSSet)
    func didReloadEvents(events:NSOrderedSet, firstLoad: Bool)
}

class ChatRoom: NSManagedObject {
    
    weak var delegate: ChatRoomDelegate?
    
    @NSManaged var objectId: String
    @NSManaged var maxOccupants: Int
    @NSManaged var numOccupants: Int
    
    @NSManaged var myAlias: Alias!
    @NSManaged var activeAliases: NSSet!
    
    @NSManaged var chatEvents: NSOrderedSet!
    
    @NSManaged func addChatEventsObject(value:ChatEvent)
    @NSManaged func removeChatEventsObject(value:ChatEvent)
    @NSManaged func addChatEvents(value:Set<ChatEvent>)
    @NSManaged func removeChatEvents(value:Set<ChatEvent>)
    
    @NSManaged func addActiveAliasesObject(value:Alias)
    @NSManaged func removeActiveAliasesObject(value:Alias)
    @NSManaged func addActiveAliases(value:Set<Alias>)
    @NSManaged func removeActiveAliases(value:Set<Alias>)
    
//    var allActions: [AnyObject] = []
//    var activeAliases: [Alias]!
    
    var currentStartToken: String! = nil
    var loadMessageCallInFlight = false
    var allMessagesLoaded = false
    
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
    
    func reload() {
        reloadActiveAlaises()
        reloadMessages()
    }
    
    func allChatEvents() -> [ChatEvent] {
        return chatEvents.array as! [ChatEvent]
    }
    
//    func messageError(message: ChatEvent) {
//        if (isMyMessage(message)) {
//            let messageIndex = findMyFirstSentMessageIndexMatchingText(message.body)
//            (allActions[messageIndex] as! Message).status = MessageStatus.Error
//            Utilities.appDelegate().saveContext()
//            self.delegate?.didUpdateEvents()
//        }
//    }
    
//    func receiveMessage(message: Message) {
//        if (isMyMessage(message)) {
//            Answers.logCustomEventWithName("Sent Message", customAttributes: ["chatRoomId":objectId, "lifeCycle":"DELIVERED"])
//            let messageIndex = findMyFirstSentMessageIndexMatchingText(message.body)
//            (allActions[messageIndex] as! Message).status = MessageStatus.Success
//            Utilities.appDelegate().saveContext()
//            self.delegate?.didUpdateEvents()
//            return;
//        }
//        
//        addMessage(message)
//    }
//    
//    func receivePresenceEvent(presenceEvent: Presence) {
//        //        if (isMyPresenceEvent(presenceEvent)) {
//        //            return;
//        //        }
//        
//        reloadActiveAlaises()
//        addPresenceEvent(presenceEvent)
//    }
    
    func reloadActiveAlaises() {
        PFCloud.callFunctionInBackground("getActiveAliases", withParameters: ["chatRoomId":myAlias.chatRoomId]) { (objects: AnyObject?, error: NSError?) -> Void in
            
            if (error != nil) {
                NSLog("error: %@", error!)
                return
            }
            
            let activeAliases = NSMutableSet()
            
            for alias in objects as! [PFObject] {
                activeAliases.addObject(Alias.createOrUpdateAliasFromParseObject(alias, isTemporary: false))
            }
            
            self.activeAliases = activeAliases
            Utilities.appDelegate().saveContext()
            
            self.delegate?.didUpdateActiveAliases(self.activeAliases)
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
        let events = chatEvents as! NSMutableOrderedSet
        events.addObject(event)
        Utilities.appDelegate().saveContext()
        self.delegate?.didUpdateEvents()
    }
    
//    func addMessage(message: ChatEvent) {
//        allActions.append(message)
//        Utilities.appDelegate().saveContext()
//        self.delegate?.didAddMessage(isMyMessage(message))
//    }
//    
//    func addPresenceEvent(newEvent: Presence) {
//        allActions.append(newEvent)
//        Utilities.appDelegate().saveContext()
//        self.delegate?.didAddPresence(isMyPresenceEvent(newEvent))
//    }
    
    //    func addMessages(newMessages: [Message]) {
    //        allActions.appendContentsOf(newMessages as [AnyObject])
    //        self.delegate?.didAddEvents(newMessages, reloaded: false, firstLoad: false)
    //    }
    //
    //    func addPresenceEvents(newEvents: [Presence]) {
    //        allActions.appendContentsOf(newEvents  as [AnyObject])
    //        self.delegate?.didAddEvents(newEvents, reloaded: false, firstLoad: false)
    //    }
    
    func findFirstMessageBeforeIndex(index: Int) -> ChatEvent! {
        var position = index - 1
        if (position < 0) {
            return nil
        }
        
        var message = chatEvents.array[position]
        while (message.type != ChatEventType.Message.rawValue) {
            position -= 1
            if (position < 0) { return nil }
            message = chatEvents.array[position]
        }
        return message as! ChatEvent
    }

    func findFirstMessageAfterIndex(index: Int) -> ChatEvent! {
        var position = index + 1
        if (position >= chatEvents.count) {
            return nil
        }
        
        var message = chatEvents.array[position]
        while (message.type != ChatEventType.Message.rawValue) {
            position += 1
            if (position >= chatEvents.count) { return nil }
            message = chatEvents.array[position]
        }
        return message as! ChatEvent
    }
//
//    func findMyFirstSentMessageIndexMatchingText(text: String) -> Int! {
//        if (allActions.count == 0) {
//            return nil
//        }
//        
//        var position = 0
//        
//        while (position < allActions.count) {
//            
//            if let thisMessage = allActions[position] as? Message {
//                if (isMyMessage(thisMessage) && thisMessage.body == text && thisMessage.status == MessageStatus.Sent) {
//                    return position
//                }
//            }
//            
//            position += 1
//        }
//        return nil
//    }
    
    func reloadMessages() {
        if (currentStartToken == nil || loadMessageCallInFlight) {
            return
        }
        
        loadMessageCallInFlight = true
        
        let params: [NSObject:AnyObject] = ["aliasId": myAlias.objectId!,
                                            "subkey":EnvironmentConstants.pubNubSubscribeKey,
                                            "endTimeToken" : currentStartToken]
        
        PFCloud.callFunctionInBackground("replayEvents", withParameters: params) { (object: AnyObject?, error: NSError?) -> Void in

            let replayEvents = NSMutableOrderedSet()
            
            if let events = object?["events"] as? [[NSObject:AnyObject]] {

                for eventDict in events {
                    
                    let objectType = eventDict["objectType"] as! String
                    let objectDict = eventDict["object"] as! [NSObject:AnyObject]
                    
                    if (objectType == "ChatEvent") {
                        replayEvents.addObject(ChatEvent.createOrUpdateEventFromServerJSON(objectDict as! [String:AnyObject]))
                    }
                }

                self.chatEvents = replayEvents
                Utilities.appDelegate().saveContext()
                
                self.delegate?.didUpdateEvents()
            }
            
            self.loadMessageCallInFlight = false
        }
    }
    
    func loadNextPageMessages() {
        
        if (allMessagesLoaded || loadMessageCallInFlight) {
            return
        }
        
        let count = 25
        
        var params: [NSObject:AnyObject] = ["count":count, "aliasId": myAlias.objectId!, "subkey":EnvironmentConstants.pubNubSubscribeKey]
        if (currentStartToken != nil) {
            params["startTimeToken"] = currentStartToken
        }
        
        loadMessageCallInFlight = true
        PFCloud.callFunctionInBackground("replayEvents", withParameters: params) { (object: AnyObject?, error: NSError?) -> Void in
            
            let replayEvents = NSMutableOrderedSet()
            
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
                        replayEvents.addObject(ChatEvent.createOrUpdateEventFromServerJSON(objectDict as! [String:AnyObject]))
                    }
                }
                
                var isFirstLoad = false
                if (self.chatEvents.count == 0) {
                    isFirstLoad = true
                }
                
                replayEvents.addObjectsFromArray(self.chatEvents.array)
                self.chatEvents = replayEvents
                Utilities.appDelegate().saveContext()
                
                self.delegate?.didReloadEvents(replayEvents, firstLoad: isFirstLoad)
            }
            
            self.loadMessageCallInFlight = false
        }
    }
    
    func shouldShowAliasLabelForMessageIndex(messageIdx: Int) -> Bool {
        let event = allChatEvents()[messageIdx]
        if (event.type == "MESSAGE") {
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
        let event = allChatEvents()[messageIdx]
        if (event.type == "MESSAGE") {
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