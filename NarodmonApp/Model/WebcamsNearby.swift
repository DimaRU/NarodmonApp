////
///  WebcamsNearby.swift
//

import Foundation

struct WebcamsNearby: Codable {
    let webcams: [Webcam]
}

struct Webcam: Codable {
    let id: Int
    let owner: String
    let my, fav: Int
    let name, location: String
    let distance: Double
    let time: Int
    let lat, lng: Double
    let liked, uptime: Int
    let image: String
}

