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
    let sensors: [FavoriteSensor]
}
