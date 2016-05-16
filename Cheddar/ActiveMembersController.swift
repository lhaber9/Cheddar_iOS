//
//  ActiveMembersController.swift
//  Cheddar
//
//  Created by Lucas Haber on 5/15/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation

protocol ActiveMembersDelegate:class {
    func activeAliases() -> [Alias]
}

class ActiveMembersController: UIViewController {
    
    weak var delegate:ActiveMembersDelegate!
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return delegate.activeAliases().count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ActiveMemberCell", forIndexPath: indexPath) as! ActiveMemberCell
        cell.nameLabel.text = delegate.activeAliases()[indexPath.row].name
//        cell.joinedAtLabel.text = delegate.activeAliases()[indexPath.row].joinedAt as String
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 44
    }
}