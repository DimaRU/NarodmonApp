////
///  GeneralSettingsViewController.swift
//

import Cocoa
import SwiftyUserDefaults

class GeneralSettingsViewController: NSViewController {

    @IBOutlet weak var email: NSTextField!
    @IBOutlet weak var password: NSSecureTextField!
    @IBOutlet weak var launchSwitch: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
 
    @IBAction func launchSwichAction(_ sender: NSButton) {
        let launchState = sender.state == .on
        setLaunchOnLogin(state: launchState)
        Defaults[.LaunchOnLogin] = launchState
    }
    
    override func viewWillDisappear() {
        KeychainService.shared[.login] = email.stringValue == "" ? nil : email.stringValue
        KeychainService.shared[.password] = password.stringValue == "" ? nil : password.stringValue
        // TODO: Login and add own sensors
    }
    
    override func viewWillAppear() {
        email.stringValue = KeychainService.shared[.login] ?? ""
        password.stringValue = KeychainService.shared[.password] ?? ""
        launchSwitch.state = Defaults[.LaunchOnLogin] ? .on : .off
    }
}
