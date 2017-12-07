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

