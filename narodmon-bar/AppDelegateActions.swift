////
///  AppDelegateActions.swift
//

import Cocoa
import SwiftyUserDefaults

// Mark: Common actions
extension AppDelegate {
    
    @IBAction func openMapAction(_ sender: Any) {
        let url = NSLocalizedString("https://narodmon.com", comment: "Open map URL")
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
