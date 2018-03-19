////
///  SensorsHistory.swift
//

import Foundation

struct SensorHistoryData: Codable {
    let time: Date
    let value: Double
}

struct SensorHistory: Codable {
    let data: [SensorHistoryData]
}
