////
///  GeneralSettingsViewController.swift
//

import Cocoa

class GeneralSettingsViewController: NSViewController {

    weak var dataStore: AppDataStore!

    @IBOutlet weak var emailTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var launchSwitch: NSButton!
    @IBOutlet weak var colorMin: NSColorWell!
    @IBOutlet weak var colorMax: NSColorWell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
 
    @IBAction func launchSwichAction(_ sender: NSButton) {
        let launchState = sender.state == .on
        setLaunchOnLogin(state: launchState)
        Defaults[.LaunchOnLogin] = launchState
    }
    
    override func viewWillDisappear() {
        dataStore.colorMin = colorMin.color
        dataStore.colorMax = colorMax.color
        dataStore.saveDefaults()
        
        let newEmail = emailTextField.stringValue == "" ? nil : emailTextField.stringValue
        let newPassword = passwordTextField.stringValue == "" ? nil : passwordTextField.stringValue
        guard KeychainService.shared[.login] != newEmail || KeychainService.shared[.password] != newPassword else { return }
        KeychainService.shared[.login] = emailTextField.stringValue == "" ? nil : emailTextField.stringValue
        KeychainService.shared[.password] = passwordTextField.stringValue == "" ? nil : passwordTextField.stringValue
        guard newEmail != nil && newPassword != nil else { return }
        
        NetService.appLoginDiscovery()
            .ensure {
                postNotification(name: .deviceListChangedNotification)
            }
            .catch { (error) in
                guard let e = error as? NarodNetworkError else { error.sendFatalReport() }
                e.displayAlert()
        }
    }
    
    override func viewWillAppear() {
        emailTextField.stringValue = KeychainService.shared[.login] ?? ""
        passwordTextField.stringValue = KeychainService.shared[.password] ?? ""
        launchSwitch.state = Defaults[.LaunchOnLogin] ? .on : .off
        colorMin.color = dataStore.colorMin
        colorMax.color = dataStore.colorMax
    }
    
}
