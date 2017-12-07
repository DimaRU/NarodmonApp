////
///  SensorsOnDevice.swift
//

import Foundation

struct SensorsOnDevice: Codable {
    let id: Int
    let owner: String
    let name: String
    let location: String
    let distance: Double
    let liked: Int
    let uptime: Int
    let my: Int?
    let cmd: Int?
    let time: Date?
    let lat: Double?
    let lng: Double?
    let sensors: [Sensor]
}

