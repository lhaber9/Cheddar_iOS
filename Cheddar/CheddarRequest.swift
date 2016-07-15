//
//  CheddarRequest.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/8/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Parse

class CheddarRequest: NSObject {
    
    static func callFunction(name: String, params: [NSObject : AnyObject],successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        PFCloud.callFunctionInBackground(name, withParameters: params) { (object: AnyObject?, error: NSError?) in
            
            if (error != nil) {
                errorCallback(error: error!)
                return
            }
            
            successCallback(object: object!)
        }
    }
    
    static func registerNewUser(email: String, password: String, successCallback: (user: PFUser) -> (), errorCallback: (error: NSError?) -> ()) {
        
        let user = PFUser()
        user.username = email
        user.email = email
        user.password = password
        
        user.signUpInBackgroundWithBlock { (completed: Bool, error: NSError?) in
            
            if (error != nil) {
                errorCallback(error: error!)
            }
            else if (!completed) {
                errorCallback(error: nil)
            }
            else {
                successCallback(user: user)
            }
        }
    }
    
    static func loginUser(email: String, password: String, successCallback: (user: PFUser) -> (), errorCallback: (error: NSError?) -> ()) {
        
        PFUser.logInWithUsernameInBackground(email,
                                             password: password)
        { (user: PFUser?, error: NSError?) in
            
            if (error != nil) {
                errorCallback(error: error!)
            }
            
            if (user != nil) {
                successCallback(user: user!)
            }
        }
    }
    
    static func currentUser() -> PFUser? {
        return PFUser.currentUser()
    }
    
    static func currentUserId() -> String? {
        return CheddarRequest.currentUser()?.objectId
    }
    
    static func currentUserIsVerified(successCallback: (isVerified: Bool) -> (), errorCallback: (error: NSError?) -> ()) {
        currentUser()?.fetchInBackgroundWithBlock({ (user: PFObject?, error: NSError?) in
            
            if (error != nil) {
                errorCallback(error: error!)
            }
            
            successCallback(isVerified: user!["emailVerified"] as! Bool)
        })
    }
    
    static func sendMessage(messageId: String, aliasId: String, body: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
    
        callFunction("sendMessage",
                     params: ["aliasId":aliasId,
                              "body":body,
                              "pubkey" :EnvironmentConstants.pubNubPublishKey,
                              "subkey" :EnvironmentConstants.pubNubSubscribeKey,
                              "messageId":messageId],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func joinNextAvailableChatRoom(userId: String, maxOccupancy:Int, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("joinNextAvailableChatRoom",
                     params: ["userId": userId,
                              "maxOccupancy": maxOccupancy,
                              "pubkey": EnvironmentConstants.pubNubPublishKey,
                              "subkey": EnvironmentConstants.pubNubSubscribeKey],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func leaveChatroom(aliasId: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("leaveChatRoom",
                     params: ["aliasId": aliasId,
                              "pubkey" : EnvironmentConstants.pubNubPublishKey,
                              "subkey" : EnvironmentConstants.pubNubSubscribeKey],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func findUser(userId: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("findUser",
                     params: ["userId":userId],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func getChatRooms(userId: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("getChatRooms",
                     params: ["userId":userId],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func getActiveAliases(chatRoomId: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("getActiveAliases",
                     params: ["chatRoomId":chatRoomId],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func replayEvents(params: [NSObject:AnyObject], successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        var mutableParams = params
        mutableParams["subkey"] = EnvironmentConstants.pubNubSubscribeKey
        
        callFunction("replayEvents",
                     params: mutableParams,
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func findAlias(aliasId: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("findAlias",
                     params: ["aliasId":aliasId],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func resendVerificationEmail(userId: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("resendVerificationEmail",
                     params: ["userId":userId],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func updateChatRoomName(aliasId: String, name: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("updateChatRoomName",
                     params: ["aliasId": aliasId,
                              "name":name,
                              "pubkey":EnvironmentConstants.pubNubPublishKey,
                              "subkey":EnvironmentConstants.pubNubSubscribeKey],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func sendFeedback(feedbackBody: String, alias: Alias, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        let build = NSBundle.mainBundle().infoDictionary?[kCFBundleVersionKey as String] as! String
        let userId = alias.userId
        let chatRoomId = alias.chatRoomId
        let aliasName = alias.name
        
        callFunction("sendFeedback",
                     params: [  "version": version,
                                "build": build,
                                "userId": userId,
                                "chatRoomId": chatRoomId,
                                "aliasName": aliasName,
                                "body": feedbackBody ],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func sendSchoolChangeRequest(schoolName: String, email: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("sendChangeSchoolRequest",
                     params: [ "schoolName": schoolName,
                               "email": email   ],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
}
