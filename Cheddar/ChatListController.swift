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
}

class ChatListController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    weak var delegate: ChatListControllerDelegate!
    
    @IBOutlet var tableView: UITableView!
    
    var chatRooms: [ChatRoom]!

    override func viewDidLoad() {
        tableView.registerNib(UINib(nibName: "ChatListCell", bundle: nil), forCellReuseIdentifier: "ChatListCell")
        reloadRooms()
    }
    
    func reloadRooms() {
        // reload from server set here
        refreshRooms() // on callback
    }
    
    func refreshRooms() {
        chatRooms = ChatRoom.fetchAll()
        tableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatRooms.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let chatRoom = chatRooms[indexPath.row]
        delegate?.showChatRoom(chatRoom)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ChatListCell", forIndexPath: indexPath) as! ChatListCell
        cell.chatNameLabel.text = chatRooms[indexPath.row].objectId
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }
    
    func closeChat() {
        dismissViewControllerAnimated(true) {
            if let selectedRow = self.tableView.indexPathForSelectedRow {
                self.tableView.deselectRowAtIndexPath(selectedRow, animated: true)
            }
        }
    }
}