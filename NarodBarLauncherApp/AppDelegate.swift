//
//  AppDelegate.swift
//  NarodBarLauncherApp
//
//  Created by Dmitriy Borovikov on 07.01.2018.
//  Copyright © 2018 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {

        let mainAppIdentifier = Bundle.main.infoDictionary!["MainAppID"] as! String
        if NSRunningApplication.runningApplications(withBundleIdentifier: mainAppIdentifier).isEmpty {
            NSWorkspace.shared.launchApplication(withBundleIdentifier: mainAppIdentifier, additionalEventParamDescriptor: nil, launchIdentifier: nil)
        }
        NSApp.terminate(nil)
    }
}
