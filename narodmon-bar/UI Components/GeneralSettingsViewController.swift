////
///  GeneralSettingsViewController.swift
//

import Cocoa

class GeneralSettingsViewController: NSViewController {

    @IBOutlet weak var email: NSTextField!
    @IBOutlet weak var password: NSSecureTextField!
    @IBOutlet weak var launchSwitch: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillDisappear() {
        KeychainService.shared[.login] = email.stringValue == "" ? nil : email.stringValue
        KeychainService.shared[.password] = password.stringValue == "" ? nil : password.stringValue
        // TODO: Login and add own sensors
    }
    
    override func viewWillAppear() {
        email.stringValue = KeychainService.shared[.login] ?? ""
        password.stringValue = KeychainService.shared[.password] ?? ""
    }
}
