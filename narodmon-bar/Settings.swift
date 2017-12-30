////
///  Settings.swift
//

import SwiftyUserDefaults

extension DefaultsKeys {
    static let Launchcount = DefaultsKey<Int>("LaunchCount")
    static let MachineUUID = DefaultsKey<String?>("MachineUUID")
    
    static let SelectedDevices = DefaultsKey<[Int]>("SelectedDevices")
    static let SelectedWindowSensors = DefaultsKey<[Int]>("SelectedWindowSensors")
    static let SelectedBarSensors = DefaultsKey<[Int]>("SelectedBarSensors")
    
    static let TinyFont = DefaultsKey<Bool>("TinyFont")
}


extension UserDefaults {

    /// Inital setup when App Started
    public func appStart() {
        Defaults[.Launchcount] += 1
        
        if Defaults[.MachineUUID] == nil {
            // First start
            let uuid = getHwUUID().md5()!
            print(uuid)
            Defaults[.MachineUUID] = uuid
        } else {
            // Not first start
            
        }
    }
    
    public func selectionExist() -> Bool {
        return !Defaults[.SelectedDevices].isEmpty && !Defaults[.SelectedBarSensors].isEmpty
    }
}

