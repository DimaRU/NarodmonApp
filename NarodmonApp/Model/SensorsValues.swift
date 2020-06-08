////
///  SensorsValues.swift
//

import Foundation

struct SensorsValues: Codable {
    let sensors: [SensorValue]
}

struct SensorValue: Codable {
    let id: Int
    let type: Int
    var value: Double
    var time: Date
    var changed: Date
    var trend: Double
}
