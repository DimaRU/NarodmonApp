////
///  Settings.swift
//

import SwiftyUserDefaults

extension DefaultsKeys {
    static let username = DefaultsKey<String?>("username")
    static let launchCount = DefaultsKey<Int>("launchCount")
}


extension UserDefaults {

    /// Inital setup when App Started
    public func appStart() {
        
    }
}

