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

class ChatListController : UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    weak var delegate: ChatListControllerDelegate!
    
    @IBOutlet var tableView: UITableView!
    
    var chatRooms: [ChatRoom]!

    override func viewDidLoad() {
        reloadRooms()
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.registerNib(UINib(nibName: "ChatListCell", bundle: nil), forCellReuseIdentifier: "ChatListCell")
    }
    
    func reloadRooms() {
        // TODO reload from server set here
        refreshRooms() // on callback
    }
    
    func refreshRooms() {
        chatRooms = ChatRoom.fetchAll()
        for chatRoom in chatRooms {
            delegate.subscribe(chatRoom)
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
        cell.chatNameLabel.text = chatRooms[indexPath.row].objectId
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }
}