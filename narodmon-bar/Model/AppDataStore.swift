////
///  AppDataStore.swift
//

import Foundation
import Cocoa
import SwiftyUserDefaults

final class AppDataStore {
    var selectedDevices: [Int] = []             // Selected device ID list
    var selectedWindowSensors: [Int] = []       // Selected popup window sensors
    var selectedWebcams: [Int] = []             // Selected webcams
    var selectedBarSensors: [Int] = []          // Selected bar sensors
    var sensorsMin: [Int:Double] = [:]
    var sensorsMax: [Int:Double] = [:]
    
    var colorMin: NSColor!
    var colorMax: NSColor!
    
    var devices: [SensorsOnDevice] = []         // Discovered devices
    var sensorValues: [SensorValue] = []        // Current sensors value
    var webcams: [WebcamImages] = []            // Discovered webcams
    
    var initData: AppInitData? = nil
    var logonData: UserLogon? = nil

    init() {
        selectedDevices = Defaults[.SelectedDevices]
        selectedWindowSensors = Defaults[.SelectedWindowSensors]
        selectedBarSensors = Defaults[.SelectedBarSensors]
        selectedWebcams = Defaults[.SelectedWebcams]
        for (key,value) in Defaults[.SensorsMin] {
            sensorsMin[Int(key)!] = value as? Double
        }
        for (key,value) in Defaults[.SensorsMax] {
            sensorsMax[Int(key)!] = value as? Double
        }
        colorMin = Defaults[.ColorMin] ?? .systemBlue
        colorMax = Defaults[.ColorMax] ?? .systemRed
    }
    
    func saveDefaults() {
        Defaults[.SelectedDevices] = selectedDevices
        Defaults[.SelectedBarSensors] = selectedBarSensors
        Defaults[.SelectedWindowSensors] = Array<Int>(selectedWindowSensors)
        Defaults[.SelectedWebcams] = Array<Int>(selectedWebcams)

        let minArray = sensorsMin.map { (String($0), $1) }
        Defaults[.SensorsMin] = Dictionary.init(uniqueKeysWithValues: minArray)
        let maxArray = sensorsMax.map { (String($0), $1) }
        Defaults[.SensorsMax] = Dictionary.init(uniqueKeysWithValues: maxArray)

        Defaults[.ColorMin] = colorMin
        Defaults[.ColorMax] = colorMax
    }
    
    func selectionExist() -> Bool {
        return !selectedDevices.isEmpty && !selectedBarSensors.isEmpty
    }
    
    func sensorData(for id: Int) -> (value: Double, unit: String, color: NSColor?)? {
        for device in devices {
            if let sensor = device.sensors.first(where: { $0.id == id }) {
                let unit = sensor.unit
                var value = sensor.value
                if let sensorValue = (sensorValues.first { $0.id == id }) {
                    value = sensorValue.value
                }
                var color: NSColor? = nil
                if let min = sensorsMin[id], value < min {
                    color = colorMin
                }
                if let max = sensorsMax[id], value > max {
                    color = colorMax
                }
                return (value, unit, color)
            }
        }
        return nil
    }
    
    func lastUpdate() -> Date? {
        guard !devices.isEmpty, !devices[0].sensors.isEmpty else { return nil }
        
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
    
    func device(for sensorId: Int) -> SensorsOnDevice? {
        for device in devices {
            if device.sensors.first(where: { $0.id == sensorId }) != nil {
                return device
            }
        }
        return nil
    }

}
