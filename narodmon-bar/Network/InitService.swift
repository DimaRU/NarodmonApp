////
///  InitService.swift
//

import Foundation

struct InitService {
    func appInit() {
        let version = Bundle.main.bundleIdentifier!
        let platform = ProcessInfo.processInfo.operatingSystemVersionString
        let model = Sysctl.model
        let utc = TimeZone.current.secondsFromGMT() / 3600
        
        NarProvider.shared.request(.appInit(version: version, platform: platform, model: model, timeZone: utc))
            .then { (data: AppInitData) -> Void in
            }
            .catch { (error) in
                
        }
    }
}
