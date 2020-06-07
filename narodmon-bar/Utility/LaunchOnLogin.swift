////
///  LaunchOnLogin.swift
//

import Foundation
import ServiceManagement

func setLaunchOnLogin(state: Bool) {
    let launcherAppID = Bundle.main.infoDictionary!["LauncherAppID"] as! CFString
    let _ = SMLoginItemSetEnabled(launcherAppID as CFString, state)
}
