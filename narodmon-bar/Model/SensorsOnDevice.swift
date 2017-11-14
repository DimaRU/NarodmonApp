////
///  SensorsOnDevice.swift
//

import Foundation

struct SensorsOnDevice: Codable {
    let id: String
    let owner: String
    let name: String
    let location: String
    let distance: Double
    let liked: Int
    let uptime: Int
    let sensors: [Sensor]
}
