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
    func didAddPresence(isMine: Bool)
    func didAddMessage(isMine: Bool)
    func didUpdateActiveAliases(aliases:[Alias])
    func didReloadEvents(events:[AnyObject], firstLoad: Bool)
}

class ChatRoom: NSManagedObject {
    
    weak var delegate: ChatRoomDelegate?
    
    @NSManaged var objectId: String
    @NSManaged var maxOccupants: Int
    @NSManaged var numOccupants: Int
    
    @NSManaged var myAlias: Alias!
    
    var allActions: [AnyObject] = []
    var activeAliases: [Alias]!
    
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
    
    func messageError(message: Message) {
        if (isMyMessage(message)) {
            let messageIndex = findMyFirstSentMessageIndexMatchingText(message.body)
            (allActions[messageIndex] as! Message).status = MessageStatus.Error
            Utilities.appDelegate().saveContext()
            self.delegate?.didUpdateEvents()
        }
    }
    
    func receiveMessage(message: Message) {
        if (isMyMessage(message)) {
            Answers.logCustomEventWithName("Sent Message", customAttributes: ["chatRoomId":objectId, "lifeCycle":"DELIVERED"])
            let messageIndex = findMyFirstSentMessageIndexMatchingText(message.body)
            (allActions[messageIndex] as! Message).status = MessageStatus.Success
            Utilities.appDelegate().saveContext()
            self.delegate?.didUpdateEvents()
            return;
        }
        
        addMessage(message)
    }
    
    func receivePresenceEvent(presenceEvent: Presence) {
        //        if (isMyPresenceEvent(presenceEvent)) {
        //            return;
        //        }
        
        reloadActiveAlaises()
        addPresenceEvent(presenceEvent)
    }
    
    func reloadActiveAlaises() {
        PFCloud.callFunctionInBackground("getActiveAliases", withParameters: ["chatRoomId":myAlias.chatRoomId]) { (objects: AnyObject?, error: NSError?) -> Void in
            
            if (error != nil) {
                NSLog("error: %@", error!)
                return
            }
            
            self.activeAliases = []
            
            for alias in objects as! [PFObject] {
                self.activeAliases.append(Alias.createAliasFromParseObject(alias, isTemporary: true))
            }
            
            Utilities.appDelegate().saveContext()
            
            self.delegate?.didUpdateActiveAliases(self.activeAliases)
        }
    }
    
    func isMyMessage(message: Message) -> Bool {
        return (message.alias.objectId == myAlias.objectId)
    }
    
    func isMyPresenceEvent(presenceEvent: Presence) -> Bool {
        return (presenceEvent.alias.objectId == myAlias.objectId)
    }
    
    func sendMessage(message: Message) {
        addMessage(message)
        Utilities.appDelegate().sendMessage(message)
    }
    
    func addMessage(message: Message) {
        allActions.append(message)
        Utilities.appDelegate().saveContext()
        self.delegate?.didAddMessage(isMyMessage(message))
    }
    
    func addPresenceEvent(newEvent: Presence) {
        allActions.append(newEvent)
        Utilities.appDelegate().saveContext()
        self.delegate?.didAddPresence(isMyPresenceEvent(newEvent))
    }
    
    //    func addMessages(newMessages: [Message]) {
    //        allActions.appendContentsOf(newMessages as [AnyObject])
    //        self.delegate?.didAddEvents(newMessages, reloaded: false, firstLoad: false)
    //    }
    //
    //    func addPresenceEvents(newEvents: [Presence]) {
    //        allActions.appendContentsOf(newEvents  as [AnyObject])
    //        self.delegate?.didAddEvents(newEvents, reloaded: false, firstLoad: false)
    //    }
    
    func findFirstMessageBeforeIndex(index: Int) -> Message! {
        var position = index - 1
        if (position < 0) {
            return nil
        }
        
        var message = allActions[position]
        while (!message.isKindOfClass(Message)) {
            position -= 1
            if (position < 0) { return nil }
            message = allActions[position]
        }
        return message as! Message
    }
    
    func findFirstMessageAfterIndex(index: Int) -> Message! {
        var position = index + 1
        if (position >= allActions.count) {
            return nil
        }
        
        var message = allActions[position]
        while (!message.isKindOfClass(Message)) {
            position += 1
            if (position >= allActions.count) { return nil }
            message = allActions[position]
        }
        return message as! Message
    }
    
    func findMyFirstSentMessageIndexMatchingText(text: String) -> Int! {
        if (allActions.count == 0) {
            return nil
        }
        
        var position = 0
        
        while (position < allActions.count) {
            
            if let thisMessage = allActions[position] as? Message {
                if (isMyMessage(thisMessage) && thisMessage.body == text && thisMessage.status == MessageStatus.Sent) {
                    return position
                }
            }
            
            position += 1
        }
        return nil
    }
    
    
    // Returns number of messages loaded
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
            
            var replayEvents = [AnyObject]()
            
            if let startToken = object?["startTimeToken"] as? String {
                self.currentStartToken = startToken
            }
            
            if let events = object?["events"] as? [[NSObject:AnyObject]] {
                
                if (events.count < count) {
                    self.allMessagesLoaded = true
                }
                else if (events.count == 1 && self.allActions.count == 1) {
                    return
                }
                
                for eventDict in events {
                    
                    let objectType = eventDict["objectType"] as! String
                    let objectDict = eventDict["object"] as! [NSObject:AnyObject]
                    
                    if (objectType == "messageEvent") {
                        replayEvents.append(Message.createMessage(objectDict))
                    }
                    else if (objectType == "presenceEvent") {
                        replayEvents.append(Presence.createPresenceEvent(objectDict))
                    }
                }
                
                var isFirstLoad = false
                if (self.allActions.count == 0) {
                    isFirstLoad = true
                }
                
                self.allActions = replayEvents + self.allActions
                Utilities.appDelegate().saveContext()
                
                self.delegate?.didReloadEvents(replayEvents, firstLoad: isFirstLoad)
            }
            
            self.loadMessageCallInFlight = false
        }
    }
    
    func shouldShowAliasLabelForMessageIndex(messageIdx: Int) -> Bool {
        if let thisMessage = allActions[messageIdx] as? Message {
            let messageBefore = findFirstMessageBeforeIndex(messageIdx)
            if (messageBefore != nil) {
                return messageBefore.alias.objectId != thisMessage.alias.objectId
            }
            else {
                return true
            }
        }
        else {
            return false
        }
    }
    
    func shouldShowAliasIconForMessageIndex(messageIdx: Int) -> Bool {
        if let thisMessage = allActions[messageIdx] as? Message {
            let messageAfter = findFirstMessageAfterIndex(messageIdx)
            if (messageAfter != nil) {
                return messageAfter.alias.objectId != thisMessage.alias.objectId
            }
            else {
                return true
            }
        }
        else {
            return false
        }
    }
    
}