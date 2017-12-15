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
    var value: Double
    let unit: String?
    var time: Date
    var changed: Date?
    var trend: Int?
}

