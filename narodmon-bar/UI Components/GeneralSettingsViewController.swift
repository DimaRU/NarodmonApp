////
///  GeneralSettingsViewController.swift
//

import Cocoa
import SwiftyUserDefaults

class GeneralSettingsViewController: NSViewController {

    @IBOutlet weak var emailTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var launchSwitch: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
 
    @IBAction func launchSwichAction(_ sender: NSButton) {
        let launchState = sender.state == .on
        setLaunchOnLogin(state: launchState)
        Defaults[.LaunchOnLogin] = launchState
    }
    
    override func viewWillDisappear() {
        let newEmail = emailTextField.stringValue == "" ? nil : emailTextField.stringValue
        let newPassword = passwordTextField.stringValue == "" ? nil : passwordTextField.stringValue
        guard KeychainService.shared[.login] != newEmail || KeychainService.shared[.password] != newPassword else { return }
        KeychainService.shared[.login] = emailTextField.stringValue == "" ? nil : emailTextField.stringValue
        KeychainService.shared[.password] = passwordTextField.stringValue == "" ? nil : passwordTextField.stringValue
        guard newEmail != nil && newPassword != nil else { return }
        
        InitService.appLoginDiscovery()
            .always {
                NotificationCenter.default.post(name: .deviceListChangedNotification, object: nil)
            }
            .catch { (error) in
                print(error)
                guard let error = error as? NarodNetworkError else { fatalError() }
                let alert = NSAlert()
                alert.messageText = error.localizedDescription
                alert.informativeText = error.message()
                alert.runModal()
        }
    }
    
    override func viewWillAppear() {
        emailTextField.stringValue = KeychainService.shared[.login] ?? ""
        passwordTextField.stringValue = KeychainService.shared[.password] ?? ""
        launchSwitch.state = Defaults[.LaunchOnLogin] ? .on : .off
    }
}
