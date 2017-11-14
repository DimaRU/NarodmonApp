////
///  Sensor.swift
//

import Foundation

struct Sensor: Codable {
    let id: Int
    let fav: Int?
    let pub: Int?
    let type: Int
    let name: String?
    let value: Double
    let unit: String?
    let time: Date
    let changed: Date?
    let trend: Int
}

struct Device: Codable {
    let id: Int
    let owner: String
    let my: Int
    let cmd: Int
    let name: String
    let location: String
    let distance: Double
    let time: Date
    let lat: Double
    let lng: Double
    let liked: Int
    let uptime: Int
    let sensors: [Sensor]
}
