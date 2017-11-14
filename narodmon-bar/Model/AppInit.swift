////
///  AppInit.swift
//

import Foundation

struct AppInit: Codable {
    let login: String
    let vip: Int
    let uid: String
    let lat: Double
    let lng: Double
    let addr: String
    let latest: String?
    let url: URL?
    let favorites: [String]
    struct `Type`: Codable {
        let type: Int
        let name: String
        let unit: String
    }
    let types: [Type]
}
