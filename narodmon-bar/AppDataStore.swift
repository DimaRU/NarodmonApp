////
///  AppDataStore.swift
//

import Foundation

class AppDataStore {
    var selectedDevices: [Int] = []             // Selected device ID list
    var selectedwindowSensors: [Int] = []       // Selected popup window sensors
    var selectedBarSensors: [Int] = []          // Selected bar sensors
    
    var devices: [Device] = []
    var sensors: [Sensor] = []
    
    var initData: AppInitData?
}
