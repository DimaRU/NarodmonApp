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
    var popover: NSPopover?
    var sensorsViewController: SensorsViewController!
    var proxyWindow: ProxyWindow?
    public var popoverShowed = false
    var lastRequestTime = Date() {
        didSet {
            print("lastRequestTime:", lastRequestTime)
        }
    }
    var sensorsRefreshTimer: Timer? = nil

    var dataStore = AppDataStore()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        Defaults.appStart()
        createContentViewController()
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusView = StatusItemView(statusItem: statusItem, dataStore: dataStore) {
            self.showPopover()
            }
        statusView.isTinyText = Defaults[.TinyFont]
        statusView.sizeToFit()
      
        NetService.appInit()
            .then { (initData: AppInitData) -> Promise<Void> in
                self.dataStore.initData = initData
                if Int(initData.uid) == 0 {
                    return NetService.appLogin()
                }
                let logonData = UserLogon(vip: initData.vip, login: initData.login, uid: initData.uid)
                self.dataStore.logonData = logonData
                return Promise.resolved()
            }
            .recover { (error) -> Void in
                if case NarodNetworkError.authorizationNeed = error {
                    let e = error as! NarodNetworkError
                    e.displayAlert()
                    return
                }
                throw error
            }
            .then {
                if self.dataStore.selectedDevices.count == 0 {
                    // No devices for display, discovery it
                    return NetService.loadDefaultDevices()
                } else {
                    return Promise.resolved()
                }
            }
            .then {
                NetService.loadDevicesDefinitions()
            }
            .then { () -> Void in
                self.dataStore.checkConsistency()
                self.dataStore.saveDefaults()
                
                postNotification(name: .deviceListChangedNotification)
                self.startRefreshCycle()
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

    func setPopoverState(showed: Bool) {
        popoverShowed = showed
        
        if showed {
            refreshDataNow()
        }
    }

    func refreshDataNow() {
        let timeInterval = -lastRequestTime.timeIntervalSinceNow
        print("refreshDataNow timeInterval:", timeInterval)
        if timeInterval > MIN_REFRESH_TIME_INTERVAL {
            NetService.loadSensorsData()
        }
    }
    
    /// Load and display data every N min
    @objc func startRefreshCycle() {

        sensorsRefreshTimer = Timer.scheduledTimer(withTimeInterval: REFRESH_TIME_INTERVAL, repeats: true) { _ in
            self.refreshDataNow()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let timer = sensorsRefreshTimer {
            timer.invalidate()
        }
        
        CacheService.clean()
    }
}


