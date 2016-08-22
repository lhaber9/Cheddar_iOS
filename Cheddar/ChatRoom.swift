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
    func didChangeIsUnloadedMessages(chatRoom: ChatRoom)
    func didUpdateName(chatRoom: ChatRoom)
    func didUpdateUnreadMessages(chatRoom:ChatRoom, areUnreadMessages: Bool)
    func didUpdateEvents(chatRoom:ChatRoom)
    func didAddEvent(chatRoom:ChatRoom, chatEvent:ChatEvent, isMine: Bool)
    func didUpdateActiveAliases(chatRoom:ChatRoom, aliases:NSSet)
    func didReloadEvents(chatRoom:ChatRoom, eventCount:Int, firstLoad: Bool)
}

class ChatRoom: NSManagedObject {
    
    weak var delegate: ChatRoomDelegate?
    
    @NSManaged var objectId: String!
    @NSManaged var name: String!
    @NSManaged var maxOccupants: NSNumber!
    @NSManaged var numOccupants: NSNumber!
    
    @NSManaged var myAlias: Alias!
    @NSManaged var activeAliases: Set<Alias>!
    
    @NSManaged var chatEvents: Set<ChatEvent>!
    var sortedChatEvents: [ChatEvent]!
    
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
    @NSManaged var areUnreadMessages: NSNumber!

    var loadMessageCallInFlight = false
    var loadAliasCallInFlight = false
    
    var pageSize = 25
    
    class func removeAll() {
        let chatRooms = fetchAll()
        for chatRoom in chatRooms {
            Utilities.appDelegate().managedObjectContext.deleteObject(chatRoom)
        }
        Utilities.appDelegate().saveContext()
    }
    
    class func newChatRoom() -> ChatRoom {
        let ent =  NSEntityDescription.entityForName("ChatRoom", inManagedObjectContext: Utilities.appDelegate().managedObjectContext)!
        let chatRoom = ChatRoom(entity: ent, insertIntoManagedObjectContext: Utilities.appDelegate().managedObjectContext)
        chatRoom.currentStartToken = nil
        chatRoom.setMessagesAllLoaded(false)
        chatRoom.setUnreadMessages(false)
        chatRoom.setChatName("Group Message")
        return chatRoom
    }
    
    class func createOrRetrieve(objectId:String) -> ChatRoom! {
        
        var chatRoom: ChatRoom!
        chatRoom = fetchById(objectId)
        
        if (chatRoom == nil) {
            return newChatRoom()
        }
        return chatRoom
    }
    
    class func createWithMyAlias(alias: Alias) -> ChatRoom {
        let newRoom = ChatRoom.newChatRoom()
        
        newRoom.objectId = alias.chatRoomId
        newRoom.myAlias = alias
        
        return newRoom
    }
    
    class func createOrUpdateChatRoomFromJson(jsonMessage: [NSObject: AnyObject], alias: Alias) -> ChatRoom! {
        
        let objectId = jsonMessage["objectId"] as? String
        let chatRoom = ChatRoom.createOrRetrieve(objectId!)
        
        chatRoom.objectId = objectId!
        chatRoom.maxOccupants = jsonMessage["maxOccupants"] as? Int
        chatRoom.numOccupants = jsonMessage["numOccupants"] as? Int
        chatRoom.myAlias = alias
    
        if let name = jsonMessage["name"] as? String where name != "" {
            chatRoom.setChatName(name)
        }
        
        return chatRoom
    }
    
    class func createOrUpdateAliasFromParseObject(pfObject: PFObject, alias: Alias) -> ChatRoom! {
        let chatRoom = ChatRoom.createOrRetrieve(pfObject.objectId!)
        
        chatRoom.objectId = pfObject.objectId!
        chatRoom.maxOccupants = pfObject.objectForKey("maxOccupants") as? Int
        chatRoom.numOccupants = pfObject.objectForKey("numOccupants") as? Int
        chatRoom.myAlias = alias
        
        if let name = pfObject.objectForKey("name") as? String where name != "" {
            chatRoom.setChatName(name)
        }
        
        return chatRoom
    }
    
    class func removeChatRoom(chatRoomId: String) {
        if let chatRoom = ChatRoom.fetchById(chatRoomId) {
            Utilities.appDelegate().managedObjectContext.deleteObject(chatRoom)
        }
        Utilities.appDelegate().unsubscribeFromPubNubChannel(chatRoomId)
        Utilities.appDelegate().unsubscribeFromPubNubPushChannel(chatRoomId)
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
    
    func setMessagesAllLoaded(allLoaded:Bool) {
        allMessagesLoaded = allLoaded
        delegate?.didChangeIsUnloadedMessages(self)
    }
    
    func setChatName(name: String) {
        self.name = name
        delegate?.didUpdateName(self)
    }
    
    func eventForIndex(index: Int) -> ChatEvent! {
        if (index >= chatEvents.count) {
            return nil
        }
        
        return sortChatEvents()[index]
    }
    
    func indexForEvent(event: ChatEvent) -> Int! {
        for (index, chatEvent) in sortChatEvents().enumerate() {
            if (chatEvent.objectId == event.objectId) {
                return index;
            }
        }
        return nil
    }
    
    func setUnreadMessages(areUnreadMessages: Bool) {
        self.areUnreadMessages = areUnreadMessages
        delegate?.didUpdateUnreadMessages(self, areUnreadMessages: areUnreadMessages)
    }
    
    func reload() {
        reloadActiveAlaises()
        reloadMessages()
    }
    
    func mostRecentChat() -> ChatEvent! {
        if (objectId == nil) {
            return nil
        }
        
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest(entityName: "ChatEvent")
        dataFetch.predicate = NSPredicate(format: "alias.chatRoomId == %@", objectId)
        dataFetch.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let results = (try moc.executeFetchRequest(dataFetch) as! [ChatEvent])
            if (results.count > 0) {
                return results[0]
            }
            return nil
        } catch {
            return nil
        }
    }
    
    func sortChatEvents() -> [ChatEvent] {
        sortedChatEvents = chatEvents.sort({ (event1: ChatEvent, event2: ChatEvent) -> Bool in
            
            var ascend = false
            
            if (event1.createdAt.compare(event2.createdAt) == NSComparisonResult.OrderedAscending){
                ascend = true
            }
            
            if (ascend && event1.status == ChatEventStatus.Sent.rawValue &&
                          event2.status != ChatEventStatus.Sent.rawValue) {
                ascend = false
            }
            else if (!ascend && event1.status != ChatEventStatus.Sent.rawValue &&
                                event2.status == ChatEventStatus.Sent.rawValue) {
                ascend = true
            }
            
            return ascend
        })
        
        return sortedChatEvents
    }
    
    func reloadActiveAlaises() {
        if (loadAliasCallInFlight) {
            return
        }
        
        loadAliasCallInFlight = true
        
        CheddarRequest.getActiveAliases(myAlias?.chatRoomId,
            successCallback: { (object) in
                
                self.loadAliasCallInFlight = false
                
                var activeAliases = Set<Alias>()
                
                for alias in object as! [PFObject] {
                    activeAliases.insert(Alias.createOrUpdateAliasFromParseObject(alias))
                }
                
                if (self.activeAliases != nil) {
                    self.removeActiveAliases(self.activeAliases)
                }
                self.addActiveAliases(activeAliases)
                
                Utilities.appDelegate().saveContext()
                
                self.delegate?.didUpdateActiveAliases(self, aliases: activeAliases)
                
            }) { (error) in
                self.loadAliasCallInFlight = false
                NSLog("error: %@", error)
                return
        }
    }
    
    func isMyChatEvent(event: ChatEvent) -> Bool {
        return (event.alias.objectId == myAlias?.objectId)
    }
    
    func sendMessage(message: ChatEvent) {
        addChatEvent(message)
        Utilities.appDelegate().sendMessage(message)
    }
    
    func addChatEvent(event: ChatEvent) {
        chatEvents.insert(event)
        Utilities.appDelegate().saveContext()
        if (event.type == ChatEventType.NameChange.rawValue) { name = event.roomName }
        self.delegate?.didAddEvent(self, chatEvent: event, isMine: isMyChatEvent(event))
    }
    
    func findFirstMessageBeforeIndex(index: Int) -> ChatEvent! {
        var position = index - 1
        if (position < 0) {
            return nil
        }
        
        var message = sortedChatEvents[position]
        while (message.type != ChatEventType.Message.rawValue) {
            position -= 1
            if (position < 0) { return nil }
            message = sortedChatEvents[position]
        }
        return message
    }

    func findFirstMessageAfterIndex(index: Int) -> ChatEvent! {
        var position = index + 1
        if (position >= chatEvents.count) {
            return nil
        }

        var message = sortedChatEvents[position]
        while (message.type != ChatEventType.Message.rawValue) {
            position += 1
            if (position >= chatEvents.count) { return nil }
            message = sortedChatEvents[position]
        }
        return message
    }
    
    func reloadMessages() {
        if (currentStartToken == nil || loadMessageCallInFlight) {
            return
        }
        
        loadMessageCallInFlight = true
        
        let params: [NSObject:AnyObject] = ["aliasId": myAlias.objectId!,
                                            "endTimeToken" : currentStartToken,
                                            "count": pageSize]
        
        CheddarRequest.replayEvents(params,
            successCallback: { (object) in
            
                var replayEvents = Set<ChatEvent>()
                
                let objectDict = object as! [NSObject:AnyObject]
                
                if let startToken = objectDict["startTimeToken"] as? String {
                    self.currentStartToken = startToken
                }
                
                if let events = objectDict["events"] as? [[NSObject:AnyObject]] {
                    
                    for eventDict in events {
                        
                        let objectType = eventDict["objectType"] as! String
                        let objectDict = eventDict["object"] as! [NSObject:AnyObject]
                        
                        if (objectType == "ChatEvent") {
                            replayEvents.insert(ChatEvent.createOrUpdateEventFromServerJSON(objectDict as! [String:AnyObject]))
                        }
                    }
                    
                    if (self.chatEvents.count > replayEvents.count) {
                        self.setMessagesAllLoaded(false)
                    }
                    
                    if (self.chatEvents != nil) {
                        self.removeChatEvents(self.chatEvents)
                    }
                    self.addChatEvents(replayEvents)
                    
                    Utilities.appDelegate().saveContext()
                    
                    self.delegate?.didUpdateEvents(self)
                    
                    if (events.count < self.pageSize) {
                        self.setMessagesAllLoaded(true)
                    }
                }
                
                self.loadMessageCallInFlight = false
                
            }) { (error) in
                
                self.loadMessageCallInFlight = false
        }
    }
    
    func loadNextPageMessages() {
        
        if (allMessagesLoaded.boolValue || loadMessageCallInFlight) {
            return
        }
        
        var params: [NSObject:AnyObject] = ["count":pageSize, "aliasId": myAlias.objectId!, "subkey":Utilities.getKeyConstant("PubnubSubscribeKey")]
        if (currentStartToken != nil) {
            params["startTimeToken"] = currentStartToken
        }
        
        loadMessageCallInFlight = true
        
        CheddarRequest.replayEvents(params,
            successCallback: { (object) in
                
                let objectDict = object as! [NSObject: AnyObject]
                
                if let startToken = objectDict["startTimeToken"] as? String {
                    self.currentStartToken = startToken
                }
                
                if let events = objectDict["events"] as? [[NSObject:AnyObject]] {
                    
                    if (events.count == 1 && self.chatEvents.count == 1) {
                        self.loadMessageCallInFlight = false
                        return
                    }
                    
                    let originalMessageCount = self.chatEvents.count
                    
                    for eventDict in events {
                        
                        let objectType = eventDict["objectType"] as! String
                        let objectDict = eventDict["object"] as! [NSObject:AnyObject]
                        
                        if (objectType == "ChatEvent") {
                            self.chatEvents.insert(ChatEvent.createOrUpdateEventFromServerJSON(objectDict as! [String:AnyObject]))
                        }
                    }
                    
                    var isFirstLoad = false
                    if (originalMessageCount <= 1) {
                        isFirstLoad = true
                    }
                    
                    Utilities.appDelegate().saveContext()
                    
                    self.delegate?.didReloadEvents(self, eventCount: events.count, firstLoad: isFirstLoad)
                    
                    if (events.count < self.pageSize) {
                        self.setMessagesAllLoaded(true)
                    }
                }
                
                self.loadMessageCallInFlight = false
                
            }) { (error) in
                
                self.loadMessageCallInFlight = false
        }
    }
    
    func shouldShowTimestampLabelForEventIndex(eventIdx: Int) -> Bool {
        if (eventIdx < 1) {
            return true
        }
        
        let event = sortedChatEvents[eventIdx]
        let eventBefore = sortedChatEvents[eventIdx - 1]
        
        let twentyMinutesAgo = event.createdAt.dateByAddingTimeInterval(-1 * 20 * 60)  // 20minutes 60seconds
        if (twentyMinutesAgo.compare(eventBefore.createdAt) == NSComparisonResult.OrderedDescending) {
            return true
        }
        return false
    }
    
    // retruns should show (aliasLabel, aliasIcon, bottomGapSize)
    func getViewSettingsForMessageCellAtIndex(messageIdx: Int) -> (Bool, Bool, CGFloat) {
        let event = sortedChatEvents[messageIdx]
        
        var shouldShowAliasLabel = false
        var shouldShowAliasIcon = false
        var bottomGapSize:CGFloat = 0
        
        
        if (event.type == ChatEventType.Message.rawValue) {
            let messageBefore = findFirstMessageBeforeIndex(messageIdx)
            let messageAfter = findFirstMessageAfterIndex(messageIdx)
            
            if (messageBefore != nil) {
                shouldShowAliasLabel = messageBefore.alias.objectId != event.alias.objectId
            }
            else {
                shouldShowAliasLabel = true
            }
            
            if (messageAfter != nil) {
                if (messageAfter.alias.objectId == event.alias.objectId) {
                    shouldShowAliasIcon = false
                    
                    let twoMinutesAhead = event.createdAt.dateByAddingTimeInterval(2 * 60)  // 2minutes 60seconds
                    if (twoMinutesAhead.compare(messageAfter.createdAt) == NSComparisonResult.OrderedAscending) {
                        bottomGapSize += ChatCell.bufferSize
                    }
                }
                else {
                    shouldShowAliasIcon = true
                    bottomGapSize += ChatCell.largeBufferSize
                }
            }
            else {
                shouldShowAliasIcon = true
                bottomGapSize += ChatCell.bufferSize
            }
        }
        
        return (shouldShowAliasLabel, shouldShowAliasIcon, bottomGapSize)
    }
}