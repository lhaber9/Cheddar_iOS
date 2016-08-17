//
//  CheddarRequest.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/8/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Crashlytics
import Parse

class CheddarRequest: NSObject {
    
    static func callFunction(name: String, params: [NSObject : AnyObject],successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        PFCloud.callFunctionInBackground(name, withParameters: params) { (object: AnyObject?, error: NSError?) in
            
            if (error != nil) {
                Crashlytics.sharedInstance().recordError(error!)
                errorCallback(error: error!)
                return
            }
            
            successCallback(object: object!)
        }
    }
    
    static func registerNewUser(email: String, password: String, registrationCode: String!, successCallback: (user: PFUser) -> (), errorCallback: (error: NSError?) -> ()) {
        
        let user = PFUser()
        user.username = email
        user.email = email
        user.password = password
        if (registrationCode != nil) {
            user.setValue(registrationCode, forKey: "registrationCode")
        }
        
        user.signUpInBackgroundWithBlock { (completed: Bool, error: NSError?) in
            if (error != nil) {
                Crashlytics.sharedInstance().recordError(error!)
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
                Crashlytics.sharedInstance().recordError(error!)
                errorCallback(error: error!)
            }
            
            if (user != nil) {
                successCallback(user: user!)
                Answers.logCustomEventWithName("Login", customAttributes: ["userId":(user?.objectId)!])
            }
        }
    }
    
    static func logoutUser(successCallback: () -> (), errorCallback: (error: NSError?) -> ()) {
        let userId = CheddarRequest.currentUser()?.objectId
        PFUser.logOutInBackgroundWithBlock { (error: NSError?) in
            if (error != nil) {
                Crashlytics.sharedInstance().recordError(error!)
                errorCallback(error: error!)
            }
            
            successCallback()
            
            Answers.logCustomEventWithName("Logout", customAttributes: ["userId":userId!])
        }
    }
    
    static func requestPasswordReset(email: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        PFUser.requestPasswordResetForEmailInBackground(email) { (completed:Bool, error: NSError?) in
            
            if (error != nil) {
                Crashlytics.sharedInstance().recordError(error!)
                errorCallback(error: error!)
            }
            
            successCallback(object: completed)
            
            Answers.logCustomEventWithName("Reset Password", customAttributes: ["email":email])
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
                Crashlytics.sharedInstance().recordError(error!)
                errorCallback(error: error!)
            }
            
            successCallback(isVerified: user!["emailVerified"] as! Bool)
        })
    }
    
    static func sendMessage(messageId: String, aliasId: String, body: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
    
        callFunction("sendMessage",
                     params: ["aliasId":aliasId,
                              "body":body,
                              "pubkey" :Utilities.getKeyConstant("PubnubPublishKey"),
                              "subkey" :Utilities.getKeyConstant("PubnubSubscribeKey"),
                              "messageId":messageId],
        successCallback: { (object) in
                        
            Answers.logCustomEventWithName("Sent Message", customAttributes: ["lifeCycle": "SENT", "aliasId": aliasId])
                        
        }, errorCallback: { (object) in
                
            Answers.logCustomEventWithName("Sent Message", customAttributes: ["lifeCycle": "FAILED", "aliasId":aliasId])
                
        })
    }
    
    static func joinNextAvailableChatRoom(userId: String, maxOccupancy:Int, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("joinNextAvailableChatRoom",
                     params: ["userId": userId,
                              "maxOccupancy": maxOccupancy,
                              "pubkey": Utilities.getKeyConstant("PubnubPublishKey"),
                              "subkey": Utilities.getKeyConstant("PubnubSubscribeKey")],
        successCallback: { (object) in
                        
            successCallback(object: object)
            Answers.logCustomEventWithName("Joined Chat", customAttributes: ["aliasId":(object as! PFObject).objectId!])
            
        }, errorCallback: errorCallback)
    }
    
    static func leaveChatroom(aliasId: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("leaveChatRoom",
                     params: [  "aliasId": aliasId,
                                "pubkey" : Utilities.getKeyConstant("PubnubPublishKey"),
                                "subkey": Utilities.getKeyConstant("PubnubSubscribeKey")],
        successCallback: { (object) in
                        
            successCallback(object: object)
            Answers.logCustomEventWithName("Left Chat", customAttributes: ["aliasId":aliasId])
                        
        }, errorCallback: errorCallback)
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
        mutableParams["subkey"] = Utilities.getKeyConstant("PubnubSubscribeKey")
        
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
        
        callFunction("resendVerificationEmail",
                     params: ["userId":userId],
        successCallback: { (object) in
            
            successCallback(object: object)
            Answers.logCustomEventWithName("Reset Password", customAttributes: ["userId":userId])
            
        }, errorCallback: errorCallback)
    }
    
    static func updateChatRoomName(aliasId: String, name: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("updateChatRoomName",
                     params: [
                        "aliasId": aliasId,
                        "name":name,
                        "pubkey": Utilities.getKeyConstant("PubnubPublishKey"),
                        "subkey": Utilities.getKeyConstant("PubnubSubscribeKey")],
        
        successCallback: { (object) in
            
            successCallback(object: object)
            Answers.logCustomEventWithName("Change Chat Name", customAttributes: ["aliasId": aliasId, "name": name])
                
        }, errorCallback: errorCallback)
    }
    
    static func sendFeedback(feedbackBody: String, alias: Alias!, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        let build = NSBundle.mainBundle().infoDictionary?[kCFBundleVersionKey as String] as! String
        let userId = CheddarRequest.currentUser()?.objectId
        
        var params = [  "platform": "iOS",
                        "environment": Utilities.envName(),
                        "version": version,
                        "build": build,
                        "userId": userId!,
                        "body": feedbackBody ]
        
        if (alias != nil) {
            params["chatRoomId"] = alias.chatRoomId
            params["aliasName"] = alias.name
        }
        
        callFunction("sendFeedback",
                     params: params,
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func sendSchoolChangeRequest(schoolName: String, email: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("sendChangeSchoolRequest",
                     params: [ "platform": "iOS",
                               "environment": Utilities.envName(),
                               "schoolName": schoolName,
                               "email": email   ],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func checkRegistrationCode(code: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("checkRegistrationCode",
                     params: [ "registrationCode": code],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
}
