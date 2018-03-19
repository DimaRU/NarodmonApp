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
    
    @IBAction func whereToBuyAction(_ sender: Any) {
        let url = NSLocalizedString("https://narodmon.ru/#!cathard", comment: "WhereToBuy URL")
        NSWorkspace.shared.open(URL(string: url)!)
    }
    
    @IBAction func makeYourOwnAction(_ sender: Any) {
        let url = NSLocalizedString("https://wifi-iot.com/a/lang/en/", comment: "MakeYourOwnAction URL")
        NSWorkspace.shared.open(URL(string: url)!)
    }
    
    @IBAction func supportAction(_ sender: Any) {
        let url = NSLocalizedString("mailto:macosapp@narodmon.com", comment: "Support email URL")
        NSWorkspace.shared.open(URL(string: url)!)
    }


    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.identifier!.rawValue {
        case "AlwaysOnTop":
            menuItem.state = Defaults[.AlwaysOnTop] ? .on : .off
        case "WhereToBuy":
            menuItem.isHidden = Locale.current.identifier != "ru_RU"
        default:
            break
        }
        return true
    }
}
