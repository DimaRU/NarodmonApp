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
                    InitService.loadDefaultDevices(isLogged: self.appDataStore.logonData != nil) {
                        self.loadDevicesDefinitions()
                    }
                } else {
                    // All ok, start refresh cycle
                    self.loadDevicesDefinitions()
                }
        }
    }

    func loadDevicesDefinitions() {
        when(fulfilled: appDataStore.selectedDevices.map { deviceId -> Promise<SensorsOnDevice> in
                NarProvider.shared.request(.sensorsOnDevice(id: deviceId)) } )
            .then { devices in
                self.appDataStore.devices = devices
            }
            .catch { error in
                print(error)
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }


}



