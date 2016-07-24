//
//  ActiveMembersController.swift
//  Cheddar
//
//  Created by Lucas Haber on 5/15/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol ActiveMembersDelegate:class {
    func currentChatRoom() -> ChatRoom
}

class ActiveMembersController: UIViewController {
    
    weak var delegate:ActiveMembersDelegate!
    @IBOutlet var titleLabel: UILabel!
    
    override func viewDidLoad() {
        titleLabel.textColor = ColorConstants.colorAccent
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Array(delegate.currentChatRoom().activeAliases).count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ActiveMemberCell", forIndexPath: indexPath) as! ActiveMemberCell
        let chatRoom = delegate.currentChatRoom()
        let alias = Array(chatRoom.activeAliases)[indexPath.row]
        cell.nameLabel.text = alias.name
        cell.setAlias(alias, chatRoom: chatRoom)
//        cell.joinedAtLabel.text = delegate.activeAliases()[indexPath.row].joinedAt as String
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
}