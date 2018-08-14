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
