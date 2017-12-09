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
    var sensors: [Sensor] = []
    
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
    
    func sensorData(for id: Int) -> (value: Double, unit: String)? {
        guard let sensor = (sensors.first { $0.id == id }) else { return nil }
        let type = initData!.types.first { $0.type == sensor.type}!
        return (sensor.value, type.unit)
    }
}
