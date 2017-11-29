//
//  KeychainService.swift
//
//  Created by Dmitriy Borovikov on 08.07.17.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import KeychainAccess

class KeychainService {
    
    public enum KeychainKeys: String {
        case login
        case password
    }

    let keychain: Keychain
    
    static let shared = KeychainService()
    
    init() {
        // Init keychain access
        let bundle = Bundle.main
        let bundleId = bundle.bundleIdentifier!
        keychain = Keychain(service: bundleId).synchronizable(true)
    }
    
    subscript(key: KeychainKeys) -> String? {
        get {
            return keychain[key.rawValue]
        }
        
        set {
            keychain[key.rawValue] = newValue
        }
    }
    
}
