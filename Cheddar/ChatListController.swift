//
//  ChatListController.swift
//  Cheddar
//
//  Created by Lucas Haber on 4/4/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Parse
import Crashlytics

protocol ChatListControllerDelegate: class {
    func forceCloseChat()
    func showChatRoom(chatRoom: ChatRoom)
    func subscribe(chatRoom:ChatRoom)
}

class ChatListController : UIViewController {
    
    weak var delegate: ChatListControllerDelegate!
    
    @IBOutlet var tableView: UITableView!
    
    var chatRooms: [ChatRoom] = []

    override func viewDidLoad() {
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.registerNib(UINib(nibName: "ChatListCell", bundle: nil), forCellReuseIdentifier: "ChatListCell")
        
        reloadRooms()
        refreshRooms()
    }
    
    func reloadRooms() {
        
        let userId = CheddarRequest.currentUserId()!
        
        CheddarRequest.findUser(userId,
            successCallback: { (object) in
            
                CheddarRequest.getChatRooms(userId,
                    successCallback: { (object) in
                    
                        let currentChatRoomIds: [String] = ChatRoom.fetchAll().map({ (chatRoom: ChatRoom) -> String in
                            return chatRoom.objectId
                        })
                        
                        let serverChatRooms = object as! [[String:AnyObject]]
                        let serverChatRoomIds: [String] = serverChatRooms.map({ (chatRoomDict: [String:AnyObject]) -> String in
                            let chatRoom = chatRoomDict["chatRoom"] as! PFObject
                            return chatRoom.objectId!
                        })
                        
                        let toDelete = Array(Set(currentChatRoomIds).subtract(Set(serverChatRoomIds)))
                        
                        for chatRoomId in toDelete {
                            ChatRoom.removeChatRoom(chatRoomId)
                        }
                        
                        for chatRoomDict in serverChatRooms {
                            let alias = Alias.createOrUpdateAliasFromParseObject(chatRoomDict["alias"] as! PFObject)
                            let chatRoom = ChatRoom.createOrUpdateAliasFromParseObject(chatRoomDict["chatRoom"] as! PFObject, alias: alias)
                            let chatEvent = ChatEvent.createOrUpdateEventFromParseObject(chatRoomDict["chatEvent"] as! PFObject)
                            if (chatEvent.objectId != chatRoom.sortChatEvents().last?.objectId) {
                                chatRoom.setUnreadMessages(true)
                            }
                        }
                        
                        Utilities.appDelegate().saveContext()
                        
                        self.refreshRooms()
                        
                    }, errorCallback: { (error) in
                        NSLog("Error getting chatrooms: %@",error)
                })
            
            }) { (error) in
            
                NSLog("%@",error)
                //devalidate user
                self.delegate.forceCloseChat()
                return
        }
    }
    
    func refreshRooms() {
        chatRooms = ChatRoom.fetchAll()
        for chatRoom in chatRooms {
            delegate.subscribe(chatRoom)
        }
        chatRooms = chatRooms.sort { (room1: ChatRoom, room2: ChatRoom) -> Bool in
            if (room1.mostRecentChat() != nil && room2.mostRecentChat() != nil) {
                if (room1.mostRecentChat().createdAt.compare(room2.mostRecentChat().createdAt) == NSComparisonResult.OrderedAscending) {
                    return false
                }
            }
            return true
        }
        tableView.reloadData()
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatRooms.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let chatRoom = chatRooms[indexPath.row]
        delegate?.showChatRoom(chatRoom)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let chatRoom = chatRooms[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier("ChatListCell", forIndexPath: indexPath) as! ChatListCell
        dispatch_async(dispatch_get_main_queue(), {
            cell.chatNameLabel.text = chatRoom.name
            cell.setMostRecentChatEvent(chatRoom.mostRecentChat(), chatRoom: chatRoom)
            cell.showUnreadIndicator(chatRoom.areUnreadMessages.boolValue)
        })
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }
}