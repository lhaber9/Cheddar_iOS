//
//  ChatRoomController.swift
//  Cheddar
//
//  Created by Lucas Haber on 3/22/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Parse

protocol ChatRoomControllerDelegate: class {
    func didUpdateEvents()
    func didUpdateActiveAliases(aliases:[Alias])
    func didAddEvents(events:[AnyObject], reloaded:Bool, firstLoad: Bool)
}

class ChatRoomController {
    
    weak var delegate: ChatRoomControllerDelegate?
    
    var allActions: [AnyObject] = []
    
    var currentStartToken: String! = nil
    var loadMessageCallInFlight = false
    var allMessagesLoaded = false
    
    var chatRoomId: String!
    var myAlias: Alias!
    
    var activeAliases: [Alias]!
    
    class func newControllerWithChatRoom(chatRoom: ChatRoom) -> ChatRoomController {
        let newController = ChatRoomController()
        newController.chatRoomId = chatRoom.objectId
        newController.myAlias = chatRoom.myAlias
        return newController
    }
    
    func receiveMessage(message: Message) {
        if (isMyMessage(message)) {
            let messageIndex = findMyFirstSentMessageIndexMatchingText(message.body)
            (allActions[messageIndex] as! Message).status = MessageStatus.Success
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
        self.delegate?.didAddEvents([presenceEvent], reloaded: false, firstLoad: false)
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
            
            self.delegate?.didUpdateActiveAliases(self.activeAliases)
        }
    }
    
    func isMyMessage(message: Message) -> Bool {
        return (message.alias.objectId == myAlias.objectId)
    }
    
    func isMyPresenceEvent(presenceEvent: Presence) -> Bool {
        return (presenceEvent.alias.objectId == myAlias.objectId)
    }
    
    func addMessage(message: Message) {
        allActions.append(message)
        self.delegate?.didAddEvents([message], reloaded: false, firstLoad: false)
    }
    
    func addPresenceEvent(newEvent: Presence) {
        allActions.append(newEvent)
        self.delegate?.didAddEvents([newEvent], reloaded: false, firstLoad: false)
    }
    
    func addMessages(newMessages: [Message]) {
        allActions.appendContentsOf(newMessages as [AnyObject])
        self.delegate?.didAddEvents(newMessages, reloaded: false, firstLoad: false)
    }
    
    func addPresenceEvents(newEvents: [Presence]) {
        allActions.appendContentsOf(newEvents  as [AnyObject])
        self.delegate?.didAddEvents(newEvents, reloaded: false, firstLoad: false)
    }
    
    func findFirstMessageBeforeIndex(index: Int) -> Message! {
        var position = index - 1
        if (position < 0) {
            return nil
        }
        
        var message = allActions[position]
        while (!message.isKindOfClass(Message)) {
            position--
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
            position++
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
        var retunIndex: Int! = nil
        
        while (retunIndex == nil && position < allActions.count) {
            
            if let thisMessage = allActions[position] as? Message {
                if (isMyMessage(thisMessage) && thisMessage.body == text && thisMessage.status == MessageStatus.Sent) {
                    retunIndex = position
                }
            }
            
            position++
        }
        return retunIndex
    }
    
    
    // Returns number of messages loaded
    func loadNextPageMessages() {
        
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
                
                self.allActions = replayEvents + self.allActions
                self.delegate?.didUpdateEvents()
                if (replayEvents.count == self.allActions.count) {
                    self.delegate?.didAddEvents(replayEvents, reloaded: true, firstLoad: true)
                }
                else {
                    self.delegate?.didAddEvents(replayEvents, reloaded: true, firstLoad: false)
                }
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