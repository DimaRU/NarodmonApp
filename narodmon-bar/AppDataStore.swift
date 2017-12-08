////
///  AppDataStore.swift
//

import Foundation
import Cocoa
import SwiftyUserDefaults

final class AppDataStore {
    var selectedDevices: [Int] = []             // Selected device ID list
    var selectedwindowSensors: [Int] = []       // Selected popup window sensors
    var selectedBarSensors: [Int] = []          // Selected bar sensors
    
    var devices: [SensorsOnDevice] = []
    
    var initData: AppInitData? = nil
    var logonData: UserLogon? = nil
    
    init() {
        selectedDevices = Defaults[.SelectedDevices]
        selectedwindowSensors = Defaults[.SelectedwindowSensors]
        selectedBarSensors = Defaults[.SelectedBarSensors]
    }
    
    func selectionExist() -> Bool {
        return !selectedDevices.isEmpty && !selectedBarSensors.isEmpty
    }

}
