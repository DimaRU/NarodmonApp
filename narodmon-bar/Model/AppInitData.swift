////
///  AppInitData.swift
//

import Foundation

struct AppInitData: Codable {
    let login: String
    let vip: Int
    let uid: String
    let lat: Double
    let lng: Double
    let addr: String
    let latest: String?
    let url: URL?
    let favorites: [String]
    let types: [SensorType]
}
