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
    var sensorsMin: [Int:Double] = [:]
    var sensorsMax: [Int:Double] = [:]
    
    var colorMin: NSColor!
    var colorMax: NSColor!
    
    var devices: [SensorsOnDevice] = []         // Discovered devices
    var sensorValues: [SensorValue] = []        // Current sensors value
    
    var initData: AppInitData? = nil
    var logonData: UserLogon? = nil

    init() {
        selectedDevices = Defaults[.SelectedDevices]
        selectedWindowSensors = Defaults[.SelectedWindowSensors]
        selectedBarSensors = Defaults[.SelectedBarSensors]
        for (key,value) in Defaults[.SensorsMin] {
            sensorsMin[Int(key)!] = value as? Double
        }
        for (key,value) in Defaults[.SensorsMax] {
            sensorsMax[Int(key)!] = value as? Double
        }
        colorMin = Defaults[.ColorMin] ?? .blue
        colorMax = Defaults[.ColorMax] ?? .red
    }
    
    func saveDefaults() {
        Defaults[.SelectedDevices] = selectedDevices
        Defaults[.SelectedBarSensors] = selectedBarSensors
        Defaults[.SelectedWindowSensors] = Array<Int>(selectedWindowSensors)
        var dict: [String:Double] = [:]
        for (key, Value) in sensorsMin {
            dict[String(key)] = Value
        }
        Defaults[.SensorsMin] = dict
        dict = [:]
        for (key, Value) in sensorsMax {
            dict[String(key)] = Value
        }
        Defaults[.SensorsMax] = dict
        
        Defaults[.ColorMin] = colorMin
        Defaults[.ColorMax] = colorMax
    }
    
    func selectionExist() -> Bool {
        return !selectedDevices.isEmpty && !selectedBarSensors.isEmpty
    }
    
    func sensorData(for id: Int) -> (value: Double, unit: String)? {
        for device in devices {
            if let sensor = device.sensors.first(where: { $0.id == id }) {
                let unit = sensor.unit
                if let sensorValue = (sensorValues.first { $0.id == id }) {
                    return (sensorValue.value, unit)
                }
                return (sensor.value, unit)
            }
        }
        return nil
    }
    
    func lastUpdate() -> Date {
        var lastTime = devices[0].sensors[0].time
        for device in devices {
            for sensor in device.sensors{
                if lastTime < sensor.time {
                    lastTime = sensor.time
                }
                if let sensor = sensorValues.first(where: { $0.id == sensor.id }) {
                    if lastTime < sensor.time {
                        lastTime = sensor.time
                    }
                }
            }
        }
        return lastTime
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
    
    func remove(device: SensorsOnDevice) {
        let sensorIds = Set<Int>(device.sensors.map { $0.id })
        
        selectedWindowSensors = selectedWindowSensors.filter { !sensorIds.contains($0) }
        selectedBarSensors = selectedBarSensors.filter { !sensorIds.contains($0) }
        selectedDevices = selectedDevices.filter{ $0 != device.id }
        let index = devices.index(where: {$0.id == device.id})!
        devices.remove(at: index)
    }
    
    func add(device: SensorsOnDevice) {
        devices.append(device)
        selectedDevices.append(device.id)
        let sensors: [Int] = device.sensors.map { $0.id }
        selectedWindowSensors.append(contentsOf: sensors)
    }

    func checkConsistency() {
        var discoveredDevices: Set<Int> = []
        var discoveredSensors: Set<Int> = []
        
        for device in devices {
            discoveredDevices.insert(device.id)
            device.sensors.forEach { discoveredSensors.insert($0.id) }
        }
        selectedDevices = selectedDevices.filter { discoveredDevices.contains($0) }
        selectedWindowSensors = selectedWindowSensors.filter { discoveredSensors.contains($0) }
        selectedBarSensors = selectedBarSensors.filter { discoveredSensors.contains($0) }
    }

}
