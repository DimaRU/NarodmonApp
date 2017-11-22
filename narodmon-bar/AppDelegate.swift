//
//  AppDelegate.swift
//  narodmon-bar
//
//  Created by Dmitriy Borovikov on 14.11.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        statusItem.button?.title = "Test"
        statusItem.button?.sendAction(on: [.leftMouseDown, .rightMouseDown, .mouseMoved])
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusItemAction)
//        statusItem.menu = NSMenu()
//        addConfigurationMenuItem()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    

}


extension AppDelegate {
    func addConfigurationMenuItem() {
        let separator = NSMenuItem(title: "Settings", action: #selector(showSettings), keyEquivalent: "")
        statusItem.menu?.addItem(separator)
    }
    
    @objc func showSettings(_ sender: NSMenuItem) {
    }
    
    @objc func statusItemAction(_ sender: NSMenuItem) {
        print("Action")
    }
}
