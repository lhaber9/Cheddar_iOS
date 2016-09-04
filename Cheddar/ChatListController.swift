//
//  ChatListController.swift
//  Cheddar
//
//  Created by Lucas Haber on 4/4/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
//import Parse
import Crashlytics

protocol ChatListControllerDelegate: class {
    func forceCloseChat()
    func showChatRoom(_ chatRoom: ChatRoom)
    func subscribe(_ chatRoom:ChatRoom)
    func tryLeaveChatRoom(_ object: AnyObject!)
    func showOverlay()
    func hideOverlay()
    func showOverlayContents(_ viewController: UIViewController)
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
        tableView.register(UINib(nibName: "ChatListCell", bundle: nil), forCellReuseIdentifier: "ChatListCell")
        tableView.allowsMultipleSelectionDuringEditing = false
        
        reloadRooms()
        refreshRooms()
        
        if (Utilities.envName() == "InternalBeta" || Utilities.envName() == "Development" ) {
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
            let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as! String
            
            developmentOnlyVersionLabel.text = "Version: " + version + " / Build: " + build + " / " + Utilities.envName()
            developmentOnlyVersionLabel.textColor = ColorConstants.textSecondary
            developmentOnlyVersionLabel.isHidden = false
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
                        
                        let toDelete = Array(Set(currentChatRoomIds).subtracting(Set(serverChatRoomIds)))
                        
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
                                
                                if (chatRoom.numberOfChatEvents() > 0 && chatEvent.objectId != chatRoom.getSortedChatEvents().last?.objectId) {
                                    chatRoom.setUnreadMessages(true)
                                }
                            }
                        }
                        
                        Utilities.appDelegate().saveContext()
                        
                        self.refreshRooms()
                        
                    }, errorCallback: { (error) in
                        NSLog("Error getting chatrooms: %@",error as NSError)
                })
            
            }) { (error) in
            
                NSLog("%@",error as NSError)
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
        chatRooms = chatRooms.sorted { (room1: ChatRoom, room2: ChatRoom) -> Bool in
            if (room1.mostRecentChat() != nil && room2.mostRecentChat() != nil) {
                if (room1.mostRecentChat().createdAt.compare(room2.mostRecentChat().createdAt as Date) == ComparisonResult.orderedAscending) {
                    return false
                }
            }
            return true
        }
        delegate.checkMaxRooms()
        tableView.reloadData()
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatRooms.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chatRoom = chatRooms[(indexPath as NSIndexPath).row]
        delegate?.showChatRoom(chatRoom)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListCell", for: indexPath) as! ChatListCell
//        dispatch_async(dispatch_get_main_queue(), {
            let chatRoom = self.chatRooms[(indexPath as NSIndexPath).row]
            cell.setMostRecentChatEvent(chatRoom.mostRecentChat(), chatRoom: chatRoom)
            cell.showUnreadIndicator(chatRoom.areUnreadMessages.boolValue)
//        })
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if (editingStyle == UITableViewCellEditingStyle.delete) {
            let chatRoom = self.chatRooms[(indexPath as NSIndexPath).row]
            delegate.tryLeaveChatRoom(chatRoom)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Leave Chatroom"
    }
    
    // MARK: FeedbackViewDelegate
    
    func myAlias() -> Alias! {
        return nil
    }
    
    func shouldCloseAll() {
        self.dismiss(animated: true, completion: nil)
        self.delegate!.hideOverlayContents()
        self.delegate!.hideOverlay()
    }
    
    // MARK: UIPopoverPresentationControllerDelegate
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showFeedbackSegue" {
            let popoverViewController = segue.destination as! FeedbackViewController
            popoverViewController.delegate = self
            popoverViewController.modalPresentationStyle = UIModalPresentationStyle.popover
            popoverViewController.popoverPresentationController!.delegate = self
        }
    }
    
    func popoverPresentationControllerShouldDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) -> Bool {
        shouldCloseAll()
        return true
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        
        // Force popover style
        return UIModalPresentationStyle.none
    }
}
