////
///  APIKeys.swift
//

import Keys


// Mark: - API Keys
struct APIKeys {
    let apiKey: String

    // MARK: Shared Keys
    static let `default`: APIKeys = {
        return APIKeys(
            apiKey: NarodmonBarKeys().apiKey
            )
    }()

    static var shared = APIKeys.default

}
