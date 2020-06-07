////
///  KeyedDecodingContainer.swift
//

import Foundation

public extension KeyedDecodingContainer  {
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        if let stringValue = try? self.decode(String.self, forKey: key) {
            guard let intValue = Int(stringValue) else {
                let context = DecodingError.Context(codingPath: codingPath, debugDescription: "Could not parse json key to a Int object")
                throw DecodingError.dataCorrupted(context)
            }
            return intValue
        }
        // Fixme: Int32
        let intValue = try self.decode(Int32.self, forKey: key)
        return Int(intValue)
    }
}
