////
///  InitService.swift
//

import Cocoa
import PromiseKit

struct InitService {

    static func appInit() -> Promise<AppInitData> {
        let version = Bundle.main.bundleIdentifier!
        let platform = ProcessInfo.processInfo.operatingSystemVersionString
        let model = Sysctl.model
        let utc = TimeZone.current.secondsFromGMT() / 3600
        
        return NarProvider.shared.request(.appInit(version: version, platform: platform, model: model, timeZone: utc))
    }
    
    static func appLogin() -> Promise<Void> {
        guard let login = KeychainService.shared[.login], let password = KeychainService.shared[.password] else {
            return Promise<Void>()
        }
        return NarProvider.shared.request(.userLogon(login: login, password: password)).asVoid()
    }

}
