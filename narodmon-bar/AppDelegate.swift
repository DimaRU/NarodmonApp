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
      
        InitService.appInit()
            .then { (initData: AppInitData) -> Promise<Void> in
                self.dataStore.initData = initData
                if Int(initData.uid) == 0 {
                    return InitService.appLogin()
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
                    return InitService.loadDefaultDevices()
                } else {
                    return Promise.resolved()
                }
            }
            .then {
                InitService.loadDevicesDefinitions()
            }
            .then { () -> Void in
                self.dataStore.checkConsistency()
                self.dataStore.saveDefaults()
                
                postNotification(name: .deviceListChangedNotification)
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

    func setPopoverState(showed: Bool) {
        popoverShowed = showed
        
        if showed {
            InitService.startRefreshCycle()     // restart refresh cycle
            InitService.refreshSensorsData()
        }
    }

    @IBAction func openMapAction(_ sender: Any) {
        let url = NSLocalizedString("http://narodmon.com", comment: "Open map URL")
        NSWorkspace.shared.open(URL(string: url)!)
    }
    
    @IBAction func alwaysOnTopToggle(_ sender: Any) {
        Defaults[.AlwaysOnTop].toogle()
        proxyWindow?.level = Defaults[.AlwaysOnTop] ? NSWindow.Level.statusBar : .normal
        if let menuItem = sender as? NSMenuItem {
            menuItem.state = Defaults[.AlwaysOnTop] ? .on : .off
        }
        
    }

    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.identifier!.rawValue == "AlwaysOnTop" {
            menuItem.state = Defaults[.AlwaysOnTop] ? .on : .off
        }
        return true
    }
}



