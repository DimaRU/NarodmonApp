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
    var sensorsRefreshTimer: Timer? = nil

    var dataStore = AppDataStore()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Defaults.appStart()

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusView = StatusItemView(statusItem: statusItem, dataStore: dataStore) {
            self.showPopover()
            }
        statusView.isTinyText = Defaults[.TinyFont]
        statusView.dataRefreshed()
      
        initPopover()

        InitService.appInit()
            .then { (initData: AppInitData) -> Promise<Void> in
                self.dataStore.initData = initData
                return InitService.appLogin()
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
                if self.dataStore.devices.count == 0 && self.dataStore.selectedBarSensors.count == 0 {
                    // No defaults for display, add it
                    InitService.loadDefaultDevices()
                        .then {
                            InitService.loadDevicesDefinitions()
                        }
                        .then { () -> Void in
                            InitService.refreshSensorsData()
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
                            InitService.refreshSensorsData()
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
        statusView.dataRefreshed()
        if popoverShowed {
            sensorsViewController.reloadData()
        }
    }
    
    func setPopoverState(showed: Bool) {
        popoverShowed = showed
        
        if showed {
            InitService.startRefreshCycle()     // restart refresh cycle
            InitService.refreshSensorsData()
        }
    }


    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}



