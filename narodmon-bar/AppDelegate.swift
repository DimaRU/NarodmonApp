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
    public var popoverShowed = false

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
            .then { (initData: AppInitData) -> Promise<UserLogon?> in
                self.appDataStore.initData = initData
                return InitService.appLogin()
            }
            .then { (logonData: UserLogon?) -> Void in
                self.appDataStore.logonData = logonData
                if logonData != nil {
                    print("Logged in")
                }
            }
            .catch { (error) in
                guard let error = error as? NarodNetworkError else { fatalError() }
                switch(error) {
                case .authorizationNeed(let message):
                    let alert = NSAlert()
                    alert.messageText = error.localizedDescription
                    alert.informativeText = message
                    alert.runModal()
                default:
                    fatalError()
                }
            }
            .always {
                if self.appDataStore.devices.count == 0 && self.appDataStore.selectedBarSensors.count == 0 {
                    // No defaults for display, add it
                    InitService.loadDefaultDevices()
                        .then {
                            InitService.loadDevicesDefinitions()
                        }
                        .then { () -> Void in
                            self.displaySensorData()
                            InitService.startRefreshCycle()
                        }
                        .catch { (error) in
                            print(error)
                            fatalError()
                    }
                } else {
                    // All ok, start refresh cycle
                    InitService.loadDevicesDefinitions()
                        .then { () -> Void in
                            self.displaySensorData()
                            InitService.startRefreshCycle()
                        }
                        .catch { (error) in
                            print(error)
                            fatalError()
                    }
                }
        }
        
    }

    /// Refresh sensor data on status bar & sensors window
    func displaySensorData() {
        
    }
    
    func setPopoverState(showed: Bool) {
        popoverShowed = showed
        
        if showed {
            InitService.startRefreshCycle()     // restart refresh cycle
        }
    }


    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}



