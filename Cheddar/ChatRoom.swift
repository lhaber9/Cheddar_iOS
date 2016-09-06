//
//  ChatRoom.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/21/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import CoreData
//import Parse
import Crashlytics

protocol ChatRoomDelegate: class {
    func didChangeIsUnloadedMessages(_ chatRoom: ChatRoom)
    func didUpdateName(_ chatRoom: ChatRoom)
    func didUpdateUnreadMessages(_ chatRoom:ChatRoom, areUnreadMessages: Bool)
    func didUpdateEvents(_ chatRoom:ChatRoom)
    func didAddEvent(_ chatRoom:ChatRoom, chatEvent:ChatEvent, isMine: Bool)
    func didUpdateActiveAliases(_ chatRoom:ChatRoom, aliases:NSSet)
    func didReloadEvents(_ chatRoom:ChatRoom, eventCount:Int, firstLoad: Bool)
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
    
    @NSManaged func addChatEventsObject(_ value:ChatEvent)
    @NSManaged func removeChatEventsObject(_ value:ChatEvent)
    @NSManaged func addChatEvents(_ value:Set<ChatEvent>)
    @NSManaged func removeChatEvents(_ value:Set<ChatEvent>)
    
    @NSManaged func addActiveAliasesObject(_ value:Alias)
    @NSManaged func removeActiveAliasesObject(_ value:Alias)
    @NSManaged func addActiveAliases(_ value:Set<Alias>)
    @NSManaged func removeActiveAliases(_ value:Set<Alias>)
    
    @NSManaged var currentStartToken: String!
    @NSManaged var allMessagesLoaded: NSNumber!
    @NSManaged var areUnreadMessages: NSNumber!

    var loadMessageCallInFlight = false
    var loadAliasCallInFlight = false
    
    var pageSize = 20
    
    class func removeAll() {
        let chatRooms = fetchAll()
        for chatRoom in chatRooms {
            Utilities.appDelegate().managedObjectContext.delete(chatRoom)
        }
        Utilities.appDelegate().saveContext()
    }
    
    class func newChatRoom() -> ChatRoom {
        let ent =  NSEntityDescription.entity(forEntityName: "ChatRoom", in: Utilities.appDelegate().managedObjectContext)!
        let chatRoom = ChatRoom(entity: ent, insertInto: Utilities.appDelegate().managedObjectContext)
        chatRoom.currentStartToken = nil
        chatRoom.setMessagesAllLoaded(false)
        chatRoom.setUnreadMessages(false)
        chatRoom.setChatName("Group Message")
        return chatRoom
    }
    
    class func createOrRetrieve(_ objectId:String) -> ChatRoom! {
        
        var chatRoom: ChatRoom!
        chatRoom = fetchById(objectId)
        
        if (chatRoom == nil) {
            return newChatRoom()
        }
        return chatRoom
    }
    
    class func createWithMyAlias(_ alias: Alias) -> ChatRoom {
        let newRoom = ChatRoom.createOrRetrieve(alias.chatRoomId)
        
        newRoom?.objectId = alias.chatRoomId
        newRoom?.myAlias = alias
        
        return newRoom!
    }
    
    class func createOrUpdateChatRoomFromJson(_ jsonMessage: NSDictionary, alias: Alias) -> ChatRoom! {
        
        let objectId = jsonMessage["objectId"] as? String
        let chatRoom = ChatRoom.createOrRetrieve(objectId!)
        
        chatRoom?.objectId = objectId!
        chatRoom?.maxOccupants = jsonMessage["maxOccupants"] as? NSNumber
        chatRoom?.numOccupants = jsonMessage["numOccupants"] as? NSNumber
        chatRoom?.myAlias = alias
    
        if let name = jsonMessage["name"] as? String , name != "" {
            chatRoom?.setChatName(name)
        }
        
        return chatRoom
    }
    
    class func createOrUpdateAliasFromParseObject(_ pfObject: PFObject, alias: Alias) -> ChatRoom! {
        let chatRoom = ChatRoom.createOrRetrieve(pfObject.objectId!)
        
        chatRoom?.objectId = pfObject.objectId!
        chatRoom?.maxOccupants = pfObject.object(forKey: "maxOccupants") as? NSNumber
        chatRoom?.numOccupants = pfObject.object(forKey: "numOccupants") as? NSNumber
        chatRoom?.myAlias = alias
        
        if let name = pfObject.object(forKey: "name") as? String , name != "" {
            chatRoom?.setChatName(name)
        }
        
        return chatRoom
    }
    
    class func removeChatRoom(_ chatRoomId: String) {
        if let chatRoom = ChatRoom.fetchById(chatRoomId) {
            Utilities.appDelegate().managedObjectContext.delete(chatRoom)
        }
        Utilities.appDelegate().unsubscribeFromPubNubChannel(chatRoomId)
        Utilities.appDelegate().unsubscribeFromPubNubPushChannel(chatRoomId)
    }
    
    class func fetchFirstRoom() -> ChatRoom! {
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatRoom")
        do {
            let result = (try moc.fetch(dataFetch) as! [ChatRoom])
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
        let dataFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatRoom")
        
        do {
            return try moc.fetch(dataFetch) as! [ChatRoom]
        } catch {
            return []
        }
    }

    class func fetchById(_ chatRoomId:String) -> ChatRoom! {
        let moc = Utilities.appDelegate().managedObjectContext
        let dataFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatRoom")
        dataFetch.predicate = NSPredicate(format: "objectId == %@", chatRoomId)
        
        do {
            let results = (try moc.fetch(dataFetch) as! [ChatRoom])
            if (results.count > 0) {
                return results[0]
            }
            return nil
        } catch {
            return nil
        }
    }
    
    func numberOfChatEvents() -> Int {
        return getSortedChatEvents().count
    }
    
    func setMessagesAllLoaded(_ allLoaded:Bool) {
        allMessagesLoaded = NSNumber(value: allLoaded)
        delegate?.didChangeIsUnloadedMessages(self)
    }
    
    func setChatName(_ name: String) {
        self.name = name
        delegate?.didUpdateName(self)
    }
    
    func eventForIndex(_ index: Int) -> ChatEvent! {
        if (index >= numberOfChatEvents()) {
            return nil
        }
        
        return getSortedChatEvents()[index]
    }
    
    func indexForEvent(_ event: ChatEvent) -> Int! {
        for (index, chatEvent) in getSortedChatEvents().enumerated() {
            if (chatEvent.objectId == event.objectId) {
                return index;
            }
        }
        return nil
    }
    
    func setUnreadMessages(_ areUnreadMessages: Bool) {
        self.areUnreadMessages = NSNumber(value: areUnreadMessages)
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
        let dataFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ChatEvent")
        dataFetch.predicate = NSPredicate(format: "alias.chatRoomId == %@", objectId)
        dataFetch.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let results = (try moc.fetch(dataFetch) as! [ChatEvent])
            if (results.count > 0) {
                for chatEvent in results {
                    if (!myAlias.deletedChatEventIdsArray().contains(chatEvent.objectId)) {
                        return chatEvent
                    }
                }
                return nil
            }
            return nil
        } catch {
            return nil
        }
    }
    
    func getSortedChatEvents() -> [ChatEvent] {
        if (sortedChatEvents == nil) {
            return sortChatEvents()
        }
        return sortedChatEvents
    }
    
    func sortChatEvents() -> [ChatEvent] {
        sortedChatEvents = chatEvents.filter({!myAlias.deletedChatEventIdsArray().contains($0.objectId)}).sorted(by: { (event1: ChatEvent, event2: ChatEvent) -> Bool in
            
            var ascend = false
            
            if (event1.createdAt.compare(event2.createdAt as Date) == ComparisonResult.orderedAscending){
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
        
        CheddarRequest.getActiveAliases((myAlias?.chatRoomId)!,
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
                
                self.delegate?.didUpdateActiveAliases(self, aliases: activeAliases as NSSet)
                
            }) { (error) in
                self.loadAliasCallInFlight = false
                NSLog("error: %@", error as NSError)
                return
        }
    }
    
    func isMyChatEvent(_ event: ChatEvent) -> Bool {
        return (event.alias.objectId == myAlias?.objectId)
    }
    
    func sendMessage(_ message: ChatEvent) {
        addChatEvent(message)
        Utilities.appDelegate().sendMessage(message)
    }
    
    func addChatEvent(_ event: ChatEvent) {
        chatEvents.insert(event)
        let _ = sortChatEvents()
        Utilities.appDelegate().saveContext()
        if (event.type == ChatEventType.NameChange.rawValue) { name = event.roomName }
        self.delegate?.didAddEvent(self, chatEvent: event, isMine: isMyChatEvent(event))
    }
    
    func findFirstMessageBeforeIndex(_ index: Int) -> ChatEvent! {
        var position = index - 1
        if (position < 0) {
            return nil
        }
        
        var message = getSortedChatEvents()[position]
        while (message.type != ChatEventType.Message.rawValue) {
            position -= 1
            if (position < 0) { return nil }
            message = getSortedChatEvents()[position]
        }
        return message
    }

    func findFirstMessageAfterIndex(_ index: Int) -> ChatEvent! {
        var position = index + 1
        if (position >= numberOfChatEvents()) {
            return nil
        }

        var message = getSortedChatEvents()[position]
        while (message.type != ChatEventType.Message.rawValue) {
            position += 1
            if (position >= numberOfChatEvents()) { return nil }
            message = getSortedChatEvents()[position]
        }
        return message
    }
    
    func reloadMessages() {
        if (loadMessageCallInFlight) {
            return
        }
        
        loadMessageCallInFlight = true
        
        let params: [String:Any] = ["aliasId": myAlias.objectId!,
                                      "count": pageSize]
        
        CheddarRequest.replayEvents(params,
            successCallback: { (object) in
            
                var replayEvents = Set<ChatEvent>()
                
                let objectDict = object as! NSDictionary
                
                if let startToken = objectDict["startTimeToken"] as? Int {
                    self.currentStartToken = String(startToken)
                }
                
                if let events = objectDict["events"] as? [NSDictionary] {
                    
                    for eventDict in events {
                        
                        let objectType = eventDict["objectType"] as! String
                        let objectDict = eventDict["object"] as! PFObject
                        
                        if (objectType == "ChatEvent") {
                            let replayEvent = ChatEvent.createOrUpdateEventFromParseObject(objectDict)
                            let objectId = replayEvent?.objectId
                            if (!self.myAlias.deletedChatEventIdsArray().contains(objectId!)) {
                                replayEvents.insert(replayEvent!)
                            }
                        }
                    }
                    
                    let startingNumberOfChatEvents = self.numberOfChatEvents()
                    
                    if (self.chatEvents != nil && replayEvents.count > 0) {
                        self.removeChatEvents(self.chatEvents)
                    }
                    self.addChatEvents(replayEvents)
                    Utilities.appDelegate().saveContext()
                    
                    self.delegate?.didUpdateEvents(self)
                    
                    if (events.count < self.pageSize) {
                        self.setMessagesAllLoaded(true)
                    } else if (startingNumberOfChatEvents > events.count) {
                        self.setMessagesAllLoaded(false)
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
        
        var params: [String:Any] = ["count":pageSize,
                                  "aliasId": myAlias.objectId!,
                                  "subkey":Utilities.getKeyConstant("PubnubSubscribeKey")]
        if (currentStartToken != nil) {
            params["startTimeToken"] = currentStartToken
        }
        
        loadMessageCallInFlight = true
        
        CheddarRequest.replayEvents(params,
            successCallback: { (object) in
                
                let objectDict = object as! NSDictionary
                
                if let startToken = objectDict["startTimeToken"] as? Int {
                    self.currentStartToken = String(startToken)
                }
                
                if let events = objectDict["events"] as? [NSDictionary] {
                    
                    if (events.count == 1 && self.numberOfChatEvents() == 1) {
                        self.loadMessageCallInFlight = false
                        return
                    }
                    
                    let originalMessageCount = self.numberOfChatEvents()
                    
                    for eventDict in events {
                        
                        let objectType = eventDict["objectType"] as! String
                        let objectDict = eventDict["object"] as! PFObject
                        
                        if (objectType == "ChatEvent") {
                            
                            let chatEvent = ChatEvent.createOrUpdateEventFromParseObject(objectDict)
                            if let objectId = chatEvent?.objectId {
                                if (!self.myAlias.deletedChatEventIdsArray().contains(objectId)) {
                                    self.chatEvents.insert(chatEvent!)
                                }
                            }
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
    
    func shouldShowTimestampLabelForEventIndex(_ eventIdx: Int) -> Bool {
        if (eventIdx < 1) {
            return true
        }
        
        let event = getSortedChatEvents()[eventIdx]
        let eventBefore = getSortedChatEvents()[eventIdx - 1]
        
        let twentyMinutesAgo = event.createdAt.addingTimeInterval(-1 * 20 * 60)  // 20minutes 60seconds
        if (twentyMinutesAgo.compare(eventBefore.createdAt as Date) == ComparisonResult.orderedDescending) {
            return true
        }
        return false
    }
    
    // retruns should show (aliasLabel, aliasIcon, bottomGapSize)
    func getViewSettingsForMessageCellAtIndex(_ messageIdx: Int) -> (Bool, Bool, CGFloat) {
        let event = getSortedChatEvents()[messageIdx]
        
        var shouldShowAliasLabel = false
        var shouldShowAliasIcon = false
        var bottomGapSize:CGFloat = 0
        
        
        if (event.type == ChatEventType.Message.rawValue) {
            let messageBefore = findFirstMessageBeforeIndex(messageIdx)
            let messageAfter = findFirstMessageAfterIndex(messageIdx)
            
            if (messageBefore != nil) {
                shouldShowAliasLabel = messageBefore?.alias.objectId != event.alias.objectId
            }
            else {
                shouldShowAliasLabel = true
            }
            
            if (messageAfter != nil) {
                if (messageAfter?.alias.objectId == event.alias.objectId) {
                    shouldShowAliasIcon = false
                    
                    let twoMinutesAhead = event.createdAt.addingTimeInterval(2 * 60)  // 2minutes 60seconds
                    if (twoMinutesAhead.compare((messageAfter?.createdAt)! as Date) == ComparisonResult.orderedAscending) {
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
