//
//  CheddarRequest.swift
//  Cheddar
//
//  Created by Lucas Haber on 6/8/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import Foundation
import Crashlytics
//import Parse

class CheddarRequest: NSObject {
    
    static func callFunction(_ name: String, params: [NSObject : AnyObject]!,successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        PFCloud.callFunction(inBackground: name, withParameters: params) { (object: AnyObject?, error: NSError?) in
            
            if (error != nil) {
                Crashlytics.sharedInstance().recordError(error!)
                errorCallback(error: error!)
                return
            }
            
            successCallback(object: object!)
        }
    }
    
    
    
    static func getMinimumBuildNumber(_ successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError?) -> ()) {
        
        callFunction("minimumIosBuildNumber",
                     params: nil,
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func registerNewUser(_ email: String, password: String, registrationCode: String!, successCallback: (_ user: PFUser) -> (), errorCallback: (_ error: NSError?) -> ()) {
        
        let user = PFUser()
        user.username = email
        user.email = email
        user.password = password
        if (registrationCode != nil) {
            user.setValue(registrationCode, forKey: "registrationCode")
        }
        
        user.signUpInBackground { (completed: Bool, error: NSError?) in
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
    
    static func loginUser(_ email: String, password: String, successCallback: (_ user: PFUser) -> (), errorCallback: (_ error: NSError?) -> ()) {
        
        PFUser.logInWithUsername(inBackground: email,
                                             password: password)
        { (user: PFUser?, error: NSError?) in
            
            if (error != nil) {
                Crashlytics.sharedInstance().recordError(error!)
                errorCallback(error: error!)
            }
            
            if (user != nil) {
                successCallback(user: user!)
                Answers.logCustomEvent(withName: "Login", customAttributes: ["userId":(user?.objectId)!])
            }
        }
    }
    
    static func logoutUser(_ successCallback: () -> (), errorCallback: (_ error: NSError?) -> ()) {
        let userId = CheddarRequest.currentUser()?.objectId
        PFUser.logOutInBackground { (error: NSError?) in
            if (error != nil) {
                Crashlytics.sharedInstance().recordError(error!)
                errorCallback(error: error!)
            }
            
            successCallback()
            
            Answers.logCustomEvent(withName: "Logout", customAttributes: ["userId":userId!])
        }
    }
    
    static func requestPasswordReset(_ email: String, successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        
        PFUser.requestPasswordResetForEmail(inBackground: email) { (completed:Bool, error: NSError?) in
            
            if (error != nil) {
                Crashlytics.sharedInstance().recordError(error!)
                errorCallback(error: error!)
            }
            
            successCallback(object: completed)
            
            Answers.logCustomEvent(withName: "Reset Password", customAttributes: ["email":email])
        }
    }
    
    static func currentUser() -> PFUser? {
        return PFUser.current()
    }
    
    static func currentUserId() -> String? {
        return CheddarRequest.currentUser()?.objectId
    }
    
    static func currentUserIsVerified(_ successCallback: (_ isVerified: Bool) -> (), errorCallback: (_ error: NSError?) -> ()) {
        currentUser()?.fetchInBackground(block: { (user: PFObject?, error: NSError?) in
            
            if (error != nil) {
                Crashlytics.sharedInstance().recordError(error!)
                errorCallback(error: error!)
            }
            
            successCallback(isVerified: user!["emailVerified"] as! Bool)
        })
    }
    
    static func sendMessage(_ messageId: String, alias: Alias, body: String, successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
    
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
    
    static func joinNextAvailableChatRoom(_ userId: String, maxOccupancy:Int, successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        
        callFunction("joinNextAvailableChatRoom",
                     params: ["userId": userId,
                              "maxOccupancy": maxOccupancy,
                              "pubkey": Utilities.getKeyConstant("PubnubPublishKey"),
                              "subkey": Utilities.getKeyConstant("PubnubSubscribeKey")],
        successCallback: { (object) in
                        
            successCallback(object: object)
            let pfObject = (object as! PFObject)
            Answers.logCustomEvent(withName: "Joined Chat", customAttributes: ["aliasId":pfObject.objectId!, "chatRoomId":pfObject["chatRoomId"]])
            
        }, errorCallback: errorCallback)
    }
    
    static func leaveChatroom(_ alias: Alias, successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        
        callFunction("leaveChatRoom",
                     params: [  "aliasId": alias.objectId,
                                "pubkey" : Utilities.getKeyConstant("PubnubPublishKey"),
                                "subkey": Utilities.getKeyConstant("PubnubSubscribeKey")],
        successCallback: { (object) in
                        
            successCallback(object: object)
            Utilities.sendAnswersEvent("Left Chat", alias: alias, attributes: [:])
                        
        }, errorCallback: errorCallback)
    }
    
    static func findUser(_ userId: String, successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        
        callFunction("findUser",
                     params: ["userId":userId],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func getChatRooms(_ userId: String, successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        
        callFunction("getChatRooms",
                     params: ["userId":userId],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func getActiveAliases(_ chatRoomId: String!, successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        
        callFunction("getActiveAliases",
                     params: ["chatRoomId":chatRoomId],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func replayEvents(_ params: [NSObject:AnyObject], successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        
        var mutableParams = params
        mutableParams["subkey"] = Utilities.getKeyConstant("PubnubSubscribeKey")
        
        callFunction("replayParseEvents",
                     params: mutableParams,
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func findAlias(_ aliasId: String, successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        
        callFunction("findAlias",
                     params: ["aliasId":aliasId],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func resendVerificationEmail(_ userId: String, successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        
        callFunction("resendVerificationEmail",
                     params: ["userId":userId],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
        
        callFunction("resendVerificationEmail",
                     params: ["userId":userId],
        successCallback: { (object) in
            
            successCallback(object: object)
            Answers.logCustomEvent(withName: "Resend Email", customAttributes: ["userId":userId])
            
        }, errorCallback: errorCallback)
    }
    
    static func updateChatRoomName(_ alias: Alias, name: String, successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        
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
    
    static func sendFeedback(_ feedbackBody: String, alias: Alias!, successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as! String
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
    
    static func sendReportUser(_ reportedAliasId: String!, chatRoomId: String!, successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        
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
    
    static func sendDeleteChatEvent(_ aliasId: String!, chatEventId: String!, successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        
        let params = [  "aliasId": aliasId!,
                        "chatEventId": chatEventId ]
        
        callFunction("deleteChatEventForAlias",
                     params: params,
                     successCallback: { (object) in
                        
                        successCallback(object: object)
                        Answers.logCustomEvent(withName: "Delete Message", customAttributes: ["aliasId":aliasId, "chatEventId":chatEventId])
                        
            }, errorCallback: errorCallback)
    }
    
    static func sendBlockUser(_ blockedUserId: String!, successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        
        let userId = CheddarRequest.currentUser()?.objectId
        let params = [  "userId": userId!,
                        "blockedUserId": blockedUserId ]
        
        callFunction("blockUserForUser",
                     params: params,
                     successCallback: { (object) in
                        
                        successCallback(object: object)
                        Answers.logCustomEvent(withName: "Block User", customAttributes: ["userId":userId!, "blockedUserId":blockedUserId])
                        
            }, errorCallback: errorCallback)
    }
    
    static func sendSchoolChangeRequest(_ schoolName: String, email: String, successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        
        callFunction("sendChangeSchoolRequest",
                     params: [ "platform": "iOS",
                               "environment": Utilities.envName(),
                               "schoolName": schoolName,
                               "email": email   ],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
    
    static func checkRegistrationCode(_ code: String, successCallback: (_ object: AnyObject) -> (), errorCallback: (_ error: NSError) -> ()) {
        
        callFunction("checkRegistrationCode",
                     params: [ "registrationCode": code],
                     successCallback: successCallback,
                     errorCallback: errorCallback)
    }
}
