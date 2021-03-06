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
    func reportAlias(alias: Alias)
}

class ActiveMembersController: UIViewController, ActiveMembersCellDelegate {
    
    weak var delegate:ActiveMembersDelegate!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        titleLabel.textColor = ColorConstants.colorAccent
    }
    
    func headerHeight() -> CGFloat {
        return 44
    }
    
    func bottomBuffer() -> CGFloat {
        return 15
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
        cell.setAlias(alias, chatRoom: chatRoom)
        cell.delegate = self
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 58
    }
    
    // MARK: ActiveMembersCellDelegate
    
    func reportAlias(alias: Alias) {
        delegate.reportAlias(alias)
    }
}