////
///  WebcamImages.swift
//

import Foundation

struct WebcamImages: Codable {
    var id: Int?
    let name: String
    let location: String
    let distance: Double
    let images: [Image]
}

struct Image: Codable {
    let time: Date
    let liked: Int
    let image: String
}
