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
    
    static func appLogin() -> Promise<UserLogon?> {
        guard let login = KeychainService.shared[.login], let password = KeychainService.shared[.password] else {
            return Promise { fulfill, reject in fulfill(nil) }
        }
        return NarProvider.shared.request(.userLogon(login: login, password: password))
    }

    static func loadDefaultDevices() -> Promise<Void> {
        let app = (NSApp.delegate as! AppDelegate)
        if app.appDataStore.logonData != nil {
            return NarProvider.shared.request(.sensorsNearby(my: true))
                .then { (near: SensorsNearby) -> Promise<(UserFavorites, SensorsNearby)> in
                    NarProvider.shared.request(.userFavorites).then { ($0, near) }
                }
                .then { (favorites, near) -> Void in
                    var sensorsIds: [Int] = []
                    for device in near.devices {
                        app.appDataStore.selectedDevices.append(device.id)
                        if (device.my ?? 0) == 1 {
                            // All sensors from my device
                            device.sensors.forEach { sensorsIds.append($0.id) }
                        }
                    }
                    favorites.sensors.forEach { sensorsIds.append($0.id) }             // Add favorited sensors
                    app.appDataStore.selectedwindowSensors = sensorsIds
                    app.appDataStore.selectedBarSensors = [Int](sensorsIds.prefix(4))  // Only first 4
                }
        } else {
            return NarProvider.shared.request(.sensorsNearby(my: false))
                // get near
                .then { (near: SensorsNearby) -> Void in
                    guard !near.devices.isEmpty else { throw NarodNetworkError.responceSyntaxError(message: "SensorsNearby") }
                    let devices = near.devices.prefix(2)
                    var sensorsIds: [Int] = []
                    for device in devices {
                        app.appDataStore.selectedDevices.append(device.id)
                        device.sensors.forEach { sensorsIds.append($0.id) }
                    }
                    app.appDataStore.selectedwindowSensors = sensorsIds
                    app.appDataStore.selectedBarSensors = [Int](sensorsIds.prefix(4))  // Only first 4
                }
        }
    }

}
