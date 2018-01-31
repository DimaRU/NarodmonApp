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
    var detachedWindow: DetachedWindow?
    public var popoverShowed = false
    var sensorsRefreshTimer: Timer? = nil

    var dataStore = AppDataStore()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Defaults.appStart()
        initPopover()

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusView = StatusItemView(statusItem: statusItem, dataStore: dataStore) {
            self.showPopover()
            }
        statusView.isTinyText = Defaults[.TinyFont]
        statusView.dataRefreshed()
      
        InitService.appInit()
            .then { (initData: AppInitData) -> Promise<Void> in
                self.dataStore.initData = initData
                if Int(initData.uid) == 0 {
                    return InitService.appLogin()
                }
                let logonData = UserLogon(vip: initData.vip, login: initData.login, uid: initData.uid)
                self.dataStore.logonData = logonData
                return Promise<Void> { fulfill, reject in
                    fulfill(())
                }
            }
            .catch { (error) in
                if let e = error as? NarodNetworkError {
                    e.displayAlert()
                    switch e {
                    case .authorizationNeed:
                        break
                    default:
                        e.sendFatalReport()
                    }
                } else {
                    error.sendFatalReport()
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
                            NotificationCenter.default.post(name: .deviceListChangedNotification, object: nil)
                            InitService.refreshSensorsData()
                            InitService.startRefreshCycle()
                        }
                        .catch { (error) in
                            if let e = error as? NarodNetworkError {
                                e.displayAlert()
                                switch e {
                                case .authorizationNeed:
                                    break
                                default:
                                    e.sendFatalReport()
                                }
                            } else {
                                error.sendFatalReport()
                            }
                    }
                } else {
                    // All ok, start refresh cycle
                    InitService.loadDevicesDefinitions()
                        .then { () -> Void in
                            NotificationCenter.default.post(name: .deviceListChangedNotification, object: nil)
                            InitService.refreshSensorsData()
                            InitService.startRefreshCycle()
                        }
                        .catch { (error) in
                            if let e = error as? NarodNetworkError {
                                e.displayAlert()
                                switch e {
                                case .authorizationNeed:
                                    break
                                default:
                                    e.sendFatalReport()
                                }
                            } else {
                                error.sendFatalReport()
                            }
                    }
                }
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



