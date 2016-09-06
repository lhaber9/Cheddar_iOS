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
    func reportAlias(_ alias: Alias)
}

class ActiveMembersController: UIViewController, ActiveMembersCellDelegate {
    
    weak var delegate:ActiveMembersDelegate!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var tableView: UITableView!
    
    static var rowHeight:CGFloat = 58
    
    override func viewDidLoad() {
        titleLabel.textColor = ColorConstants.colorAccent
    }
    
    func headerHeight() -> CGFloat {
        return 44
    }
    
    func bottomBuffer() -> CGFloat {
        return 15
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Array(delegate.currentChatRoom().activeAliases).count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAtIndexPath indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActiveMemberCell", for: indexPath as IndexPath) as! ActiveMemberCell
        let chatRoom = delegate.currentChatRoom()
        let alias = Array(chatRoom.activeAliases)[indexPath.row]
        cell.setAlias(alias, chatRoom: chatRoom)
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAtIndexPath indexPath: IndexPath) -> CGFloat {
        return ActiveMembersController.rowHeight
    }
    
    // MARK: ActiveMembersCellDelegate
    
    func reportAlias(_ alias: Alias) {
        delegate.reportAlias(alias)
    }
}
