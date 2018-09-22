////
///  AppVersion.swift
//

import Cocoa

func appVersion() -> String {
    let dictionary = Bundle.main.infoDictionary!
    let bundleVersion = dictionary["CFBundleShortVersionString"] as! String
    let bundleBuild = dictionary["CFBundleVersion"] as! String
    let version = "\(bundleVersion).\(bundleBuild)"
    return version
}

/// Check if app need update
///
/// - Returns: true if need
func checkAppUpdate() -> Bool {
    let dictionary = Bundle.main.infoDictionary!
    let bundleBuildString = dictionary["CFBundleVersion"] as! String
    let appBuild = Int(bundleBuildString)!
    
    let app = (NSApp.delegate as! AppDelegate)
    guard let targetBuild = Int(app.dataStore.initData?.latest ?? "") else {
        return false
    }
    return targetBuild > appBuild
}
