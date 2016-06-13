//
//  AppDelegate.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/1/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import UIKit
import PubNub
import Parse
import CoreData
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PNObjectEventListener, UIAlertViewDelegate {

    var window: UIWindow?
    var pnClient: PubNub!
    
    var userIdFieldName = "cheddarUserId"
    var deviceDidOnboardFieldName = "cheddarDeviceHasOnboarded"
    var appVersionFieldName = "cheddarAppVersion"
    var thisDeviceToken: NSData!
    
    var messagesToSend: [ChatEvent] = []
    var sendingMessages: Bool = false

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        let configuration = PNConfiguration(publishKey: EnvironmentConstants.pubNubPublishKey,
                                          subscribeKey: EnvironmentConstants.pubNubSubscribeKey)
        pnClient = PubNub.clientWithConfiguration(configuration)
        pnClient.addListener(self)
        
        Parse.setApplicationId(EnvironmentConstants.parseApplicationId, clientKey:EnvironmentConstants.parseClientKey)
        
        Fabric.sharedSDK().debug = true
        Fabric.with([Crashlytics.self])
        
//        initializeUser()
        if ( isUpdate() ) {
            //            UIAlertView(title: "New In This Version", message: "-Fix the issue with missing text in some messages\n-Messages are selectable and recognize links\n-New loading animation\n-Shrink chat bar slightly\n-Keyboard hides when scrolling up messages (velocity threshold)\n-No longer scroll down on new messages, “new message” button appears instead\n", delegate: nil, cancelButtonTitle: "OK").show()
        }
        
        let types: UIUserNotificationType = [.Badge, .Sound, .Alert]
        
        let textAction = UIMutableUserNotificationAction()
        textAction.identifier = "TEXT_ACTION"
        textAction.title = "Reply"
        textAction.activationMode = .Background
        textAction.authenticationRequired = false
        textAction.destructive = false
        if #available(iOS 9.0, *) {
            textAction.behavior = .TextInput
        } else {
            // Fallback on earlier versions
        }
        
        let category = UIMutableUserNotificationCategory()
        category.identifier = "ACTIONABLE_REPLY"
        category.setActions([textAction], forContext: .Default)
        category.setActions([textAction], forContext: .Minimal)
        
        let categories = NSSet(object: category) as! Set<UIUserNotificationCategory>
        let mySettings = UIUserNotificationSettings(forTypes: types, categories: categories)
        
        UIApplication.sharedApplication().registerUserNotificationSettings(mySettings)
        UIApplication.sharedApplication().registerForRemoteNotifications()
        
        let buildNum = Int(NSBundle.mainBundle().infoDictionary?[kCFBundleVersionKey as String] as! String)
        
        PFCloud.callFunctionInBackground("minimumIosBuildNumber", withParameters: nil) { (object: AnyObject?, error: NSError?) -> Void in
            
            if (error != nil) {
                return
            }
            
            let minmumBuildNum = object as! Int
            
            if (minmumBuildNum > buildNum) {
                UIAlertView(title: "Unsupported Version", message: "This version of Cheddar is no longer supported. Visit our app store page to update!", delegate: nil, cancelButtonTitle: "OK").show()
            }
        }
        
        return true
    }
    
    func deviceDidOnboard() -> Bool {
        let defaults = NSUserDefaults.standardUserDefaults()
        let didOnboard = defaults.boolForKey(deviceDidOnboardFieldName)
        if (didOnboard) {
            return true
        }
        return false
    }
    
    func setDeviceOnboarded() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(true, forKey: self.deviceDidOnboardFieldName)
        defaults.synchronize()
    }
    
//    func initializeUser() {
//        let defaults = NSUserDefaults.standardUserDefaults()
//        if let userId = defaults.stringForKey(userIdFieldName) {
//            User.theUser.objectId = userId
//            return
//        }
//        
//        PFCloud.callFunctionInBackground("registerNewUser", withParameters: nil) { (object: AnyObject?, error: NSError?) -> Void in
//            let user = object as! PFUser
//            User.theUser.objectId = user.objectId
//            defaults.setValue(user.objectId, forKey: self.userIdFieldName)
//            defaults.setValue(false, forKey: self.userDidOnboardFieldName)
//            defaults.synchronize()
//        }
//    }
    
//    func reinitalizeUser() {
//        let defaults = NSUserDefaults.standardUserDefaults()
//        User.theUser.objectId = nil
//        defaults.setValue(nil, forKey: self.userIdFieldName)
//        defaults.setValue(false, forKey: self.userDidOnboardFieldName)
//        defaults.synchronize()
//        initializeUser()
//    }
    
    func isUpdate() -> Bool {
        let build = NSBundle.mainBundle().infoDictionary?[kCFBundleVersionKey as String] as! String
        var isUpdated = false
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let appVersion = defaults.stringForKey(appVersionFieldName) {
            if (appVersion != build) {
                isUpdated = true
                defaults.setValue(build, forKey: appVersionFieldName)
                defaults.synchronize()
            }
        }
        else {
            isUpdated = true
            defaults.setValue(build, forKey: appVersionFieldName)
            defaults.synchronize()
        }
        
        return isUpdated
    }
    
    func sendMessage(message: ChatEvent) {
        messagesToSend.append(message)
        if (!sendingMessages) {
            sendingMessages = true
            pushPubNubMessages()
        }
    }
    
    func pushPubNubMessages() {
        if (messagesToSend.count == 0) {
            sendingMessages = false
            return
        }
        
        let message = messagesToSend.first!
        
        CheddarRequest.sendMessage(message.messageId,
                                   aliasId: message.alias.objectId!,
                                   body: message.body,
            successCallback: { (object) in
                
                self.messagesToSend.removeAtIndex(0)
                self.pushPubNubMessages()
                
            }) { (error) in
                
                NSLog("%@",error);
                Answers.logCustomEventWithName("Sent Message", customAttributes: ["chatRoomId": message.alias.chatRoomId, "lifeCycle":"FAILED"])
                message.status = ChatEventStatus.Error.rawValue
                self.saveContext()
                let chatRoom = ChatRoom.fetchById(message.alias.chatRoomId)
                chatRoom.delegate?.didUpdateEvents(chatRoom)
        }
    }
    
    func sendFeedback(text: String, alias: Alias) {
        
        let version = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
        let build = NSBundle.mainBundle().infoDictionary?[kCFBundleVersionKey as String] as! String
        let userId = alias.userId
        let chatRoomId = alias.chatRoomId
        let aliasName = alias.name
        
        var sendBody = "Version: " + version + "\n"
        sendBody += "Build: " + build + "\n"
        sendBody += "UserId: " + userId + "\n"
        sendBody += "ChatRoomId: " + chatRoomId + "\n"
        sendBody += "AliasName: " + aliasName + "\n"
        sendBody += text + "\n"
        sendBody += "-----------------------"
        
        let urlString = "https://hooks.slack.com/services/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"
        let url = NSURL(string: urlString)
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        request.HTTPBody = "payload={\"text\": \"\(sendBody)\"}".dataUsingEncoding(NSUTF8StringEncoding)
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue()) {(response, data, error) in
            
        }
    }
    
    func subscribeToPubNubChannel(channelId: String) {
        self.pnClient.subscribeToChannels([channelId], withPresence: true)
    }
    
    func subscribeToPubNubPushChannel(channelId: String) {
        pnClient.addPushNotificationsOnChannels([channelId], withDevicePushToken: thisDeviceToken) { (status: PNAcknowledgmentStatus!) -> Void in
            
            // Check whether request successfully completed or not.
            if (!status.error) {
                
                // Handle successful push notification enabling on passed channels.
            }
                // Request processing failed.
            else {
                
                // Handle modification error. Check 'category' property to find out possible issue because
                // of which request did fail.
                //
                // Request can be resent using: [status retry];
            }
        }
    }
    
    func unsubscribeFromPubNubChannel(channelId: String) {
        self.pnClient.unsubscribeFromChannels([channelId], withPresence: true)
    }
    
    func unsubscribeFromPubNubPushChannel(channelId: String) {
        pnClient.removePushNotificationsFromChannels([channelId], withDevicePushToken: thisDeviceToken) { (status: PNAcknowledgmentStatus!) -> Void in
            
            // Check whether request successfully completed or not.
            if (!status.error) {
                
                // Handle successful push notification enabling on passed channels.
            }
                // Request processing failed.
            else {
                
                // Handle modification error. Check 'category' property to find out possible issue because
                // of which request did fail.
                //
                // Request can be resent using: [status retry];
            }
        }
    }
    
    func client(client: PubNub!, didReceiveMessage message: PNMessageResult!) {
        let jsonMessage = message.data.message as! [NSObject:AnyObject]
        let objectType = jsonMessage["objectType"] as! String
        let objectDict = jsonMessage["object"] as! [String:AnyObject]
        
        if (objectType == "ChatEvent") {
            let chatEvent = ChatEvent.createOrUpdateEventFromServerJSON(objectDict)
            chatEvent.status = ChatEventStatus.Success.rawValue
            
            if let chatRoom = ChatRoom.fetchById(chatEvent.alias.chatRoomId) {
                chatRoom.addChatEvent(chatEvent)
                
                if (chatEvent.type == ChatEventType.Presence.rawValue) {
                    chatRoom.reloadActiveAlaises()
                }
            }
        }
        
        saveContext()
    }
    
    func client(client: PubNub!, didReceivePresenceEvent event: PNPresenceEventResult!) {
    }
    
    func client(client: PubNub!, didReceiveStatus status: PNStatus!) {
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "teset.test" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Model.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            let mOptions = [NSMigratePersistentStoresAutomaticallyOption: true,
                            NSInferMappingModelAutomaticallyOption: true]
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: mOptions)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    // Notifications
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        thisDeviceToken = deviceToken
        NSUserDefaults.standardUserDefaults().setObject(deviceToken, forKey:"DeviceToken")
        NSUserDefaults.standardUserDefaults().synchronize()
        
        NSNotificationCenter.defaultCenter().postNotificationName("didSetDeviceToken", object: nil)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        NSLog("error: %@", error);
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, completionHandler: () -> Void) {
        
        NSLog("HERE1")
    }
    
    func application(application: UIApplication, handleActionWithIdentifier identifier: String?, forLocalNotification notification: UILocalNotification, withResponseInfo responseInfo: [NSObject : AnyObject], completionHandler: () -> Void) {
        
        NSLog("here")
        
        if #available(iOS 9.0, *) {
            let reply = responseInfo[UIUserNotificationActionResponseTypedTextKey]
            NSLog(String(reply))
            
        } else {
            // Fallback on earlier versions
        }
        
        completionHandler()
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        
    }

}

