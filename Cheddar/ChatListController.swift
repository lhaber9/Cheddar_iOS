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
        PFCloud.callFunctionInBackground("findUser", withParameters: ["userId":User.theUser.objectId]) { (object: AnyObject?, error: NSError?) -> Void in
            
            if ((error) != nil) {
                NSLog("%@",error!)
                //devalidate user
                
                return
            }
            
            PFCloud.callFunctionInBackground("getChatRooms", withParameters: ["userId":User.theUser.objectId]) { (object: AnyObject?, error: NSError?) -> Void in
                
                if ((error) != nil) {
                    NSLog("%@",error!)
                    return
                }
                
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
                    ChatRoom.createOrUpdateAliasFromParseObject(chatRoomDict["chatRoom"] as! PFObject, alias: alias)
                    ChatEvent.createOrUpdateEventFromParseObject(chatRoomDict["chatEvent"] as! PFObject)
                }
                
                Utilities.appDelegate().saveContext()
                
                self.refreshRooms()
            }
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
        let cell = tableView.dequeueReusableCellWithIdentifier("ChatListCell", forIndexPath: indexPath) as! ChatListCell
        cell.chatNameLabel.text = chatRooms[indexPath.row].name
        let mostRecentChat = chatRooms[indexPath.row].mostRecentChat()
        if (mostRecentChat != nil) {
            cell.lastMessageLabel.text = mostRecentChat.alias.name + ": " + mostRecentChat.body
        }
        else {
            cell.lastMessageLabel.text = "No Activity"
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }
}