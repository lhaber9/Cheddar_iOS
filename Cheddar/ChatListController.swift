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
    func tryLeaveChatRoom(object: AnyObject!)
    func showOverlay()
    func hideOverlay()
    func showOverlayContents(viewController: UIViewController)
    func hideOverlayContents()
    func checkMaxRooms()
}

class ChatListController : UIViewController, UITableViewDelegate, UITableViewDataSource, UIPopoverPresentationControllerDelegate, FeedbackViewDelegate {
    
    weak var delegate: ChatListControllerDelegate!
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var developmentOnlyVersionLabel: UILabel!
    
    var chatRooms: [ChatRoom] = []

    override func viewDidLoad() {
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.registerNib(UINib(nibName: "ChatListCell", bundle: nil), forCellReuseIdentifier: "ChatListCell")
        tableView.allowsMultipleSelectionDuringEditing = false
        
        reloadRooms()
        refreshRooms()
        
        if (Utilities.envName() == "InternalBeta" || Utilities.envName() == "Development" ) {
            let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
            let build = NSBundle.mainBundle().infoDictionary?[kCFBundleVersionKey as String] as! String
            
            developmentOnlyVersionLabel.text = "Version: " + version + " / Build: " + build + " / " + Utilities.envName()
            developmentOnlyVersionLabel.textColor = ColorConstants.textSecondary
            developmentOnlyVersionLabel.hidden = false
        }
        
        view.layoutIfNeeded()
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
                            var alias: Alias! = nil
                            var chatRoom: ChatRoom! = nil
                            var chatEvent: ChatEvent! = nil
                            
                            if let aliasDict = chatRoomDict["alias"] as? PFObject {
                                alias = Alias.createOrUpdateAliasFromParseObject(aliasDict)
                                
                                if let chatRoomDict = chatRoomDict["chatRoom"] as? PFObject {
                                    chatRoom = ChatRoom.createOrUpdateAliasFromParseObject(chatRoomDict, alias: alias)
                                }
                            }
                            
                            if let chatEventDict = chatRoomDict["chatEvent"] as? PFObject {
                                chatEvent = ChatEvent.createOrUpdateEventFromParseObject(chatEventDict)
                            }
                            
                            if (chatRoom != nil && chatEvent != nil) {
                                
                                if (chatRoom.numberOfChatEvents() > 0 && chatEvent.objectId != chatRoom.sortChatEvents().last?.objectId) {
                                    chatRoom.setUnreadMessages(true)
                                }
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
                CheddarRequest.logoutUser({ 
                    
                    }, errorCallback: { (error) in
                        
                })
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
        delegate.checkMaxRooms()
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
//        dispatch_async(dispatch_get_main_queue(), {
            let chatRoom = self.chatRooms[indexPath.row]
            cell.setMostRecentChatEvent(chatRoom.mostRecentChat(), chatRoom: chatRoom)
            cell.showUnreadIndicator(chatRoom.areUnreadMessages.boolValue)
//        })
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            let chatRoom = self.chatRooms[indexPath.row]
            delegate.tryLeaveChatRoom(chatRoom)
        }
    }
    
    func tableView(tableView: UITableView, titleForDeleteConfirmationButtonForRowAtIndexPath indexPath: NSIndexPath) -> String? {
        return "Leave Chatroom"
    }
    
    // MARK: FeedbackViewDelegate
    
    func myAlias() -> Alias! {
        return nil
    }
    
    func shouldCloseAll() {
        self.dismissViewControllerAnimated(true, completion: nil)
        self.delegate!.hideOverlayContents()
        self.delegate!.hideOverlay()
    }
    
    // MARK: UIPopoverPresentationControllerDelegate
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showFeedbackSegue" {
            let popoverViewController = segue.destinationViewController as! FeedbackViewController
            popoverViewController.delegate = self
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.Popover
            popoverViewController.popoverPresentationController!.delegate = self
        }
    }
    
    func popoverPresentationControllerWillDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        shouldCloseAll()
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        
        // Force popover style
        return UIModalPresentationStyle.None
    }
}