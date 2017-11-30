////
///  Settings.swift
//

import SwiftyUserDefaults

extension DefaultsKeys {
    static let username = DefaultsKey<String?>("username")
    static let launchCount = DefaultsKey<Int>("launchCount")
    static let machineUUID = DefaultsKey<String?>("machineUUID")
    static let selectedDevices = DefaultsKey<[Int]>("selectedDevices")
    static let selectedwindowSensors = DefaultsKey<[Int]>("selectedwindowSensors")
    static let selectedBarSensors = DefaultsKey<[Int]>("selectedBarSensors")
    static let tinyFont = DefaultsKey<Bool>("tinyFont")
}


extension UserDefaults {

    /// Inital setup when App Started
    public func appStart() {
        Defaults[.launchCount] = Defaults[.launchCount] + 1
        
        if Defaults[.machineUUID] == nil {
            // First start
            let uuid = getHwUUID().md5()!
            print(uuid)
            Defaults[.machineUUID] = uuid
        } else {
            // Not first start
            
        }
    }
}

