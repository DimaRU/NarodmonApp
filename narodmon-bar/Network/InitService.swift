////
///  InitService.swift
//

import Cocoa

struct InitService {
    static func appInit() {
        let version = Bundle.main.bundleIdentifier!
        let platform = ProcessInfo.processInfo.operatingSystemVersionString
        let model = Sysctl.model
        let utc = TimeZone.current.secondsFromGMT() / 3600
        
        NarProvider.shared.request(.appInit(version: version, platform: platform, model: model, timeZone: utc))
            .then { (initData: AppInitData) -> Void in
                let app  = NSApp.delegate as! AppDelegate
                app.appDataStore.initData = initData
                print(initData)
            }
            .catch { (error) in
                switch error {
                case let e as NarodNetworkError:
                    print(e.message())
                default:
                    print(error.localizedDescription)
                }
                fatalError("Can't init")
        }
    }
}
