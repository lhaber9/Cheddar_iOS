//
//  RenameChatController.swift
//  Cheddar
//
//  Created by Lucas Haber on 5/13/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Parse

protocol RenameChatDelegate:class {
    func currentChatRoomName() -> String!
    func myAlias() -> Alias!
    func shouldCloseAll()
}

class RenameChatController: UIViewController {
    
    weak var delegate:RenameChatDelegate!
    
    @IBOutlet var chatRoomTitleText: UITextField!

    override func viewDidLoad() {
        chatRoomTitleText.text = delegate.currentChatRoomName()
    }
    
    @IBAction func sendTap() {
        PFCloud.callFunctionInBackground("updateChatRoomName", withParameters: ["aliasId": delegate.myAlias().objectId,"name":chatRoomTitleText.text!,"pubkey":EnvironmentConstants.pubNubPublishKey, "subkey":EnvironmentConstants.pubNubSubscribeKey]) { (object: AnyObject?, error: NSError?) -> Void in
            
            self.delegate.shouldCloseAll()
        }
    }
}