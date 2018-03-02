////
///  SensorsHistory.swift
//

import Foundation

struct SensorsHistory: Codable {
    struct SensorData: Codable {
        let id: Int
        let time: Date
        let value: Double
    }
    let data: [SensorData]
}
