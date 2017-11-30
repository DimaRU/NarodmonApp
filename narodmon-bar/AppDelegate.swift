//
//  AppDelegate.swift
//  narodmon-bar
//
//  Created by Dmitriy Borovikov on 14.11.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusView: StatusItemView!
    var myPopover: NSPopover?
    var sensorsViewController: SensorsViewController!
    var detachedWindow: NSWindow?
    
    var appDataStore = AppDataStore()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Defaults.appStart()

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusView = StatusItemView(statusItem: statusItem) {
            print("Action")
            self.showPopover()
            }
        statusView.sizeToFit()
      
        initPopover()

        //InitService.appInit()
        
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}



