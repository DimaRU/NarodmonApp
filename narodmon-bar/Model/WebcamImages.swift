////
///  WebcamImages.swift
//

import Foundation

struct WebcamImages: Codable {
    let name: String
    let location: String
    let distance: Double
    let images: [Image]
}

struct Image: Codable {
    let time: Int
    let liked: Int
    let image: String
}
