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
    @IBOutlet var sendLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    var callInFlight = false
    
    override func viewDidLoad() {
        chatRoomTitleText.text = delegate.currentChatRoomName()
        chatRoomTitleText.becomeFirstResponder()
    }
    
    @IBAction func sendTap() {
        if (callInFlight || chatRoomTitleText.text == "") {
            return
        }
        
        callInFlight = true
        activityIndicator.startAnimating()
        UIView.animateWithDuration(0.33) { 
            self.sendLabel.alpha = 0
            self.activityIndicator.alpha = 1
            self.view.layoutIfNeeded()
        }
        
        PFCloud.callFunctionInBackground("updateChatRoomName", withParameters: ["aliasId": delegate.myAlias().objectId,"name":chatRoomTitleText.text!,"pubkey":EnvironmentConstants.pubNubPublishKey, "subkey":EnvironmentConstants.pubNubSubscribeKey]) { (object: AnyObject?, error: NSError?) -> Void in
            
            self.callInFlight = false
            self.delegate.shouldCloseAll()
        }
    }
}