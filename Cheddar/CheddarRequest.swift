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
    
    static func callFunction(name: String, params: [NSObject : AnyObject]!,successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        PFCloud.callFunctionInBackground(name, withParameters: params) { (object: AnyObject?, error: NSError?) in
            
            if (error != nil) {
                Crashlytics.sharedInstance().recordError(error!)
                errorCallback(error: error!)
                return
            }
            
            successCallback(object: object!)
        }
    }
    
    
    
    static func getMinimumBuildNumber(successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError?) -> ()) {
        
        callFunction("minimumIosBuildNumber",
                     params: nil,
                     successCallback: successCallback,
                     errorCallback: errorCallback)
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
    
    static func sendMessage(messageId: String, alias: Alias, body: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
    
        callFunction("sendMessage",
                     params: ["aliasId":alias.objectId,
                              "body":body,
                              "pubkey" :Utilities.getKeyConstant("PubnubPublishKey"),
                              "subkey" :Utilities.getKeyConstant("PubnubSubscribeKey"),
                              "messageId":messageId],
        successCallback: { (object) in
            
            successCallback(object: object)
            Utilities.sendAnswersEvent("Sent Message", alias: alias, attributes: ["lifeCycle": "SENT"])
                        
        }, errorCallback: { (object) in
            
            errorCallback(error: object)
            Utilities.sendAnswersEvent("Sent Message", alias: alias, attributes: ["lifeCycle": "FAILED"])
                
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
            let pfObject = (object as! PFObject)
            Answers.logCustomEventWithName("Joined Chat", customAttributes: ["aliasId":pfObject.objectId!, "chatRoomId":pfObject["chatRoomId"]])
            
        }, errorCallback: errorCallback)
    }
    
    static func leaveChatroom(alias: Alias, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("leaveChatRoom",
                     params: [  "aliasId": alias.objectId,
                                "pubkey" : Utilities.getKeyConstant("PubnubPublishKey"),
                                "subkey": Utilities.getKeyConstant("PubnubSubscribeKey")],
        successCallback: { (object) in
                        
            successCallback(object: object)
            Utilities.sendAnswersEvent("Left Chat", alias: alias, attributes: [:])
                        
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
    
    static func getActiveAliases(chatRoomId: String!, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("getActiveAliases",
                     params: ["chatRoomId":chatRoomId],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func replayEvents(params: [NSObject:AnyObject], successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        var mutableParams = params
        mutableParams["subkey"] = Utilities.getKeyConstant("PubnubSubscribeKey")
        
        callFunction("replayParseEvents",
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
            Answers.logCustomEventWithName("Resend Email", customAttributes: ["userId":userId])
            
        }, errorCallback: errorCallback)
    }
    
    static func updateChatRoomName(alias: Alias, name: String, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        callFunction("updateChatRoomName",
                     params: [
                        "aliasId": alias.objectId,
                        "name":name,
                        "pubkey": Utilities.getKeyConstant("PubnubPublishKey"),
                        "subkey": Utilities.getKeyConstant("PubnubSubscribeKey")],
        
        successCallback: { (object) in
            
            successCallback(object: object)
            Utilities.sendAnswersEvent("Change Chat Name", alias: alias, attributes: ["name": name])
                
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
    
    static func sendReportUser(reportedAliasId: String!, chatRoomId: String!, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        let userId = CheddarRequest.currentUser()?.objectId
        let params = [  "environment": Utilities.envName(),
                        "userId": userId!,
                        "reportedAliasId": reportedAliasId,
                        "chatRoomId": chatRoomId]
        
        callFunction("sendReportUser",
                     params: params,
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func sendDeleteChatEvent(aliasId: String!, chatEventId: String!, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        let params = [  "aliasId": aliasId!,
                        "chatEventId": chatEventId ]
        
        callFunction("deleteChatEventForAlias",
                     params: params,
                     successCallback: { (object) in
                        
                        successCallback(object: object)
                        Answers.logCustomEventWithName("Delete Message", customAttributes: ["aliasId":aliasId, "chatEventId":chatEventId])
                        
            }, errorCallback: errorCallback)
    }
    
    static func sendBlockUser(blockedUserId: String!, successCallback: (object: AnyObject) -> (), errorCallback: (error: NSError) -> ()) {
        
        let userId = CheddarRequest.currentUser()?.objectId
        let params = [  "userId": userId!,
                        "blockedUserId": blockedUserId ]
        
        callFunction("blockUserForUser",
                     params: params,
                     successCallback: { (object) in
                        
                        successCallback(object: object)
                        Answers.logCustomEventWithName("Block User", customAttributes: ["userId":userId!, "blockedUserId":blockedUserId])
                        
            }, errorCallback: errorCallback)
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
