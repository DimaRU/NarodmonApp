////
///  AppDataStore.swift
//

import Foundation
import Cocoa
import SwiftyUserDefaults

final class AppDataStore {
    var selectedDevices: [Int] = []             // Selected device ID list
    var selectedWindowSensors: [Int] = []       // Selected popup window sensors
    var selectedBarSensors: [Int] = []          // Selected bar sensors
    
    var devices: [SensorsOnDevice] = []         // Discovered devices
    var sensorValue: [SensorValue] = []         // Current sensors value
    
    var initData: AppInitData? = nil
    var logonData: UserLogon? = nil
    
    init() {
        selectedDevices = Defaults[.SelectedDevices]
        selectedWindowSensors = Defaults[.SelectedWindowSensors]
        selectedBarSensors = Defaults[.SelectedBarSensors]
    }
    
    func saveDefaults() {
        Defaults[.SelectedDevices] = selectedDevices
        Defaults[.SelectedBarSensors] = selectedBarSensors
        Defaults[.SelectedWindowSensors] = Array<Int>(selectedWindowSensors)
    }
    
    func selectionExist() -> Bool {
        return !selectedDevices.isEmpty && !selectedBarSensors.isEmpty
    }
    
    func sensorData(for id: Int) -> (value: Double, unit: String)? {
        if let sensor = (sensorValue.first { $0.id == id }) {
            let type = initData!.types.first { $0.type == sensor.type}!
            return (sensor.value, type.unit)
        }
        else {
            for device in devices {
                if let sensor = device.sensors.first(where: { $0.id == id }) {
                    let type = initData!.types.first { $0.type == sensor.type}!
                    return (sensor.value, type.unit)
                }
            }
        }
        return nil
    }
    
    func windowSelectionsList() -> [Any] {
        var list: [Any] = []
        for device in devices {
            let sensorsList: [Any] = device.sensors.filter{ selectedWindowSensors.contains($0.id) }
            if !sensorsList.isEmpty {
                list.append(device)
                list.append(contentsOf: sensorsList)
            }
        }
        return list
    }
    
    func devicesSensorsList() -> [Any] {
        var list: [Any] = []
        for device in devices where selectedDevices.contains(device.id) {
            list.append(device)
            let sensors: [Any] = device.sensors
            list.append(contentsOf: sensors)
        }
        return list
    }

}
