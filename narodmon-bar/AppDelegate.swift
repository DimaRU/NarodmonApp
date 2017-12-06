//
//  AppDelegate.swift
//  narodmon-bar
//
//  Created by Dmitriy Borovikov on 14.11.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import PromiseKit
import SwiftyUserDefaults

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var statusView: StatusItemView!
    var myPopover: NSPopover?
    var sensorsViewController: SensorsViewController!
    
    var appDataStore = AppDataStore()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Defaults.appStart()

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusView = StatusItemView(statusItem: statusItem) {
            self.showPopover()
            }
        statusView.sizeToFit()
      
        initPopover()

        InitService.appInit()
            .then { (initData: AppInitData) -> Promise<Void> in
                self.appDataStore.initData = initData
                return InitService.appLogin()
            }
            .then {
                // Login
                print("Logged in")
            }
            .catch { (error) in
                if let error = error as? NarodNetworkError {
                    switch(error) {
                    case .authorizationNeed(let message):
                        let alert = NSAlert()
                        alert.messageText = error.localizedDescription
                        alert.informativeText = message
                        alert.runModal()
                    default:
                        fatalError()
                    }
                } else {
                    fatalError()
                }
            }
            .always {
                // All ok, start refresh cycle
        }

        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}



