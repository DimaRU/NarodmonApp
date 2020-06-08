////
///  UserFavorites.swift
//

import Foundation

struct UserFavorites: Codable {
    struct FavoriteSensor: Codable {
        let id: Int
        let type: Int
        let name: String
        let value: Double
        let time: Date
    }
    struct Webcam: Codable {
        let id: Int
        let name: String
        let time: Int
        let image: String
    }

    let sensors: [FavoriteSensor]
    let webcams: [Webcam]
}
