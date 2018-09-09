////
///  WebcamImages.swift
//

import Foundation

struct WebcamImages: Codable {
    let images: [Image]
}

struct Image: Codable {
    let time: Int
    let liked: Int
    let image: String
}
