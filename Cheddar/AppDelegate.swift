
//
//  AppDelegate.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/1/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import UIKit
//import PubNub
//import Parse
import CoreData
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PNObjectEventListener, UIAlertViewDelegate {

    var window: UIWindow?
    var pnClient: PubNub!
    
    var userIdFieldName = "cheddarUserId"
    var deviceDidOnboardFieldName = "cheddarDeviceHasOnboarded"
    var deviceDidAgreeTosFieldName = "deviceDidAgreeTos"
    var appVersionFieldName = "cheddarAppVersion"
    var thisDeviceToken: Data!
    
    var messagesToSend: [ChatEvent] = []
    var sendingMessages: Bool = false
    
    var termsOfServiceAlert: UIAlertView!
    var mustUpdateAlert: UIAlertView!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        
        let configuration = PNConfiguration(publishKey:  Utilities.getKeyConstant("PubnubPublishKey"),
                                          subscribeKey:  Utilities.getKeyConstant("PubnubSubscribeKey"))
        pnClient = PubNub.client(with: configuration)
        pnClient.add(self)
        
        Parse.setApplicationId( Utilities.getKeyConstant("ParseAppId"), clientKey: Utilities.getKeyConstant("ParseClientKey"))
        
        mustUpdateAlert = UIAlertView(title: "Unsupported Version", message: "This version of Cheddar is no longer supported. Visit our app store page to update!", delegate: self, cancelButtonTitle: "OK")
        
        termsOfServiceAlert = UIAlertView(title: "Terms of Service", message: "Using this app means agree to Cheddar’s terms of service, found at neucheddar.com/tos", delegate: nil, cancelButtonTitle: "I Accept", otherButtonTitles: "View Terms")
        
        mustUpdateAlert.delegate = self
        termsOfServiceAlert.delegate = self
        
        if ( isUpdate() ) {
            UIAlertView(title: "New in this version", message: "This update contains full support for iOS 10! \n \n Thank you to everyone for your feedback, keep it coming!", delegate: nil, cancelButtonTitle: "Ok").show()
        }
        
        let types: UIUserNotificationType = [.badge, .sound, .alert]
        
        let textAction = UIMutableUserNotificationAction()
        textAction.identifier = "TEXT_ACTION"
        textAction.title = "Reply"
        textAction.activationMode = .background
        textAction.isAuthenticationRequired = false
        textAction.isDestructive = false
        if #available(iOS 9.0, *) {
            textAction.behavior = .textInput
        } else {
            // Fallback on earlier versions
        }
        
        let category = UIMutableUserNotificationCategory()
        category.identifier = "ACTIONABLE_REPLY"
        category.setActions([textAction], for: .default)
        category.setActions([textAction], for: .minimal)
        
        let categories = NSSet(object: category) as! Set<UIUserNotificationCategory>
        let mySettings = UIUserNotificationSettings(types: types, categories: categories)
        
        UIApplication.shared.registerUserNotificationSettings(mySettings)
        UIApplication.shared.registerForRemoteNotifications()
        
//        Fabric.sharedSDK().debug = true
        Fabric.with([Crashlytics.self])
        
        return true
    }
    
    func deviceDidOnboard() -> Bool {
        let defaults = UserDefaults.standard
        let didOnboard = defaults.bool(forKey: deviceDidOnboardFieldName)
        if (didOnboard) {
            return true
        }
        return false
    }
    
    func setDeviceOnboarded() {
        let defaults = UserDefaults.standard
        defaults.setValue(true, forKey: self.deviceDidOnboardFieldName)
        defaults.synchronize()
    }
    
    func deviceDidAgreeTos() -> Bool {
        let defaults = UserDefaults.standard
        let didAgree = defaults.bool(forKey: deviceDidAgreeTosFieldName)
        if (didAgree) {
            return true
        }
        return false
    }
    
    func setDeviceAgreeTos() {
        let defaults = UserDefaults.standard
        defaults.setValue(true, forKey: self.deviceDidAgreeTosFieldName)
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
        let build = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as! String
        var isUpdated = false
        
        let defaults = UserDefaults.standard
        if let appVersion = defaults.string(forKey: appVersionFieldName) {
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
    
    func sendMessage(_ message: ChatEvent) {
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
        
        CheddarRequest.sendMessage(message.messageId!,
                                   alias: message.alias!,
                                   body: message.body!,
            successCallback: { (object) in
                
                self.messagesToSend.remove(at: 0)
                self.pushPubNubMessages()
                
            }) { (error) in
                
                message.status = ChatEventStatus.Error.rawValue
                self.saveContext()
                let chatRoom = ChatRoom.fetchById(message.alias.chatRoomId)
                chatRoom?.delegate?.didUpdateEvents(chatRoom!)
        }
    }
    
    func subscribeToPubNubChannel(_ channelId: String) {
        self.pnClient.subscribe(toChannels: [channelId], withPresence: true)
    }
    
    
    
    
    func subscribeToPubNubPushChannel(_ channelId: String) {
        
        pnClient.addPushNotifications(onChannels: [channelId], withDevicePushToken: thisDeviceToken) { (status: PNAcknowledgmentStatus?) in
            
            // Check whether request successfully completed or not.
            if (!(status?.isError)!) {
                
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
    
    func unsubscribeFromPubNubChannel(_ channelId: String) {
        self.pnClient.unsubscribe(fromChannels: [channelId], withPresence: true)
    }
    
    func unsubscribeFromPubNubPushChannel(_ channelId: String) {
        pnClient.removePushNotifications(fromChannels: [channelId], withDevicePushToken: thisDeviceToken) { (status: PNAcknowledgmentStatus?) -> Void in
            
            // Check whether request successfully completed or not.
            if (!(status?.isError)!) {
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
    
    func client(_ client: PubNub!, didReceiveMessage message: PNMessageResult!) {
        let jsonMessage = message.data.message as! NSDictionary
        let objectType = jsonMessage["objectType"] as! String
        let objectDict = jsonMessage["object"] as! NSDictionary
        
        if (objectType == "ChatEvent") {
            let chatEvent = ChatEvent.createOrUpdateEventFromServerJSON(objectDict)
            chatEvent?.status = ChatEventStatus.Success.rawValue
            
            if let chatRoom = ChatRoom.fetchById((chatEvent?.alias.chatRoomId)!) {
                chatRoom.addChatEvent(chatEvent!)
                
                if (chatEvent?.type == ChatEventType.Presence.rawValue) {
                    chatRoom.reloadActiveAlaises()
                }
            }
        }
        
        saveContext()
    }
    
    func client(_ client: PubNub!, didReceivePresenceEvent event: PNPresenceEventResult!) {
    }
    
    func client(_ client: PubNub!, didReceive status: PNStatus!) {
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "applicationDidBecomeActive"), object: nil)
        
        CheddarRequest.getMinimumBuildNumber({ (object) in
            
            let minmumBuildNum = object as! Int
            
            let currentBuildNum = Int(Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as! String)
            
            if (minmumBuildNum > currentBuildNum!) {
                self.mustUpdateAlert?.show()
            }
            
        }) { (error) in
            return
        }
        
        if (!deviceDidAgreeTos()) {
            termsOfServiceAlert?.show()
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "teset.test" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Model", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("Model.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            let mOptions = [NSMigratePersistentStoresAutomaticallyOption: true,
                            NSInferMappingModelAutomaticallyOption: true]
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: mOptions)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject
            
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
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
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
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        thisDeviceToken = deviceToken
        UserDefaults.standard.set(deviceToken, forKey:"DeviceToken")
        UserDefaults.standard.synchronize()
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "didSetDeviceToken"), object: nil)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        //NSLog("error: %@", error);
    }
    
    @nonobjc func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: () -> Void) {
        
    }
    
    @nonobjc func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, withResponseInfo responseInfo: NSDictionary, completionHandler: () -> Void) {
        
        if #available(iOS 9.0, *) {
            let reply = responseInfo[UIUserNotificationActionResponseTypedTextKey]
            NSLog(String(describing: reply))
            
        } else {
            // Fallback on earlier versions
        }
        
        completionHandler()
    }
    
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        if (alertView.isEqual(mustUpdateAlert)) {
            let iTunesLink = "https://itunes.apple.com/us/app/cheddar-anonymous-group-messaging/id1086160475?ls=1&mt=8"
            UIApplication.shared.openURL(URL(string: iTunesLink)!)
        } else if (alertView.isEqual(termsOfServiceAlert)) {
            if (buttonIndex == 0) {
                self.setDeviceAgreeTos()
            } else if (buttonIndex == 1) {
                let termsOfServiceLink = "http://neucheddar.com/tos"
                UIApplication.shared.openURL(URL(string: termsOfServiceLink)!)
            }
        }
    }
}

