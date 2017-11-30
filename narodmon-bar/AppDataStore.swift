////
///  AppDataStore.swift
//

import Foundation
import Cocoa
import SwiftyUserDefaults

final class AppDataStore {
    var selectedDevices: Set<Int> = []             // Selected device ID list
    var selectedwindowSensors: Set<Int> = []       // Selected popup window sensors
    var selectedBarSensors: Set<Int> = []          // Selected bar sensors
    
    var devices: [Device] = []
    var sensors: [Sensor] = []
    
    var initData: AppInitData?
    
    init() {
        selectedDevices = Set<Int>(Defaults[.SelectedDevices])
        selectedwindowSensors = Set<Int>(Defaults[.SelectedwindowSensors])
        selectedBarSensors = Set<Int>(Defaults[.SelectedBarSensors])
    }
    
    func selectionExist() -> Bool {
        return !selectedDevices.isEmpty && !selectedBarSensors.isEmpty
    }

}
