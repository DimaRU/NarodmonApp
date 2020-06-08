////
///  SensorsHistory.swift
//

import Foundation

struct SensorHistoryData: Codable {
    let time: Date
    let value: Double
    
    init(time: Date, value: Double) {
        self.time = time
        self.value = value
    }
}

struct SensorHistory: Codable {
    let data: [SensorHistoryData]
}
