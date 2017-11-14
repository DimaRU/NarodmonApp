////
///  SensorsHistory.swift
//

import Foundation

struct SensorsHistory: Codable {
    struct Data: Codable {
        let id: Int
        let time: Date
        let value: Double
    }
    let data: [Data]
}