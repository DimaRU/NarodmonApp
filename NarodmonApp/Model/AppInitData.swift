////
///  AppInitData.swift
//

import Foundation

struct AppInitData: Codable {
    let login: String
    let vip: Int?
    let uid: Int
    let addr: String
    let latest: String?
    let types: [SensorType]?
}
