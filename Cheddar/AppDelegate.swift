//
//  AppDelegate.swift
//  Cheddar
//
//  Created by Lucas Haber on 2/1/16.
//  Copyright © 2016 Lucas Haber. All rights reserved.
//

import UIKit
import PubNub

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PNObjectEventListener {

    var window: UIWindow?
    var pnClient: PubNub?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
//        [self.client publish: @"Hello from PubNub iOS!" toChannel: @"my_channel" storeInHistory:YES
//        withCompletion:^(PNPublishStatus *status)
        
        let configuration = PNConfiguration(publishKey: "XXXX", subscribeKey: "XXXX")
        let client = PubNub.clientWithConfiguration(configuration)
        client.addListener(self)
        client.subscribeToChannels(["test"], withPresence: true)
        
        client.publish("Hello", toChannel: "test", mobilePushPayload: ["test":"test"], storeInHistory: true, withCompletion: { (status: PNPublishStatus!) -> Void in
            
        })
        
        pnClient = client
        
        return true
    }
    
    func client(client: PubNub!, didReceiveMessage message: PNMessageResult!) {
        
        
        NSLog("here1")
    }
    
    func client(client: PubNub!, didReceivePresenceEvent event: PNPresenceEventResult!) {
        NSLog("here2")
    }
    
    func client(client: PubNub!, didReceiveStatus status: PNStatus!) {
        NSLog("here3")
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
    }


}

