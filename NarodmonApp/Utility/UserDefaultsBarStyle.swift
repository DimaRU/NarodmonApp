//
//  UserDefaultsBarStyle.swift
//  NarodmonBar
//
//  Created by Dmitriy Borovikov on 01.02.2018.
//  Copyright © 2018 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

func isDarkMenuBar() -> Bool {
    return UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
}
