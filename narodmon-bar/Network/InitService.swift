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
            return Promise<Void> { fulfill, reject in
                fulfill(())
            }
        }
        let app = (NSApp.delegate as! AppDelegate)
        guard let initData = app.dataStore.initData else { fatalError("Login without initData") }
        if Int(initData.uid) != 0 {
            let logonData = UserLogon(vip: initData.vip, login: initData.login, uid: initData.uid)
            app.dataStore.logonData = logonData
            // Already logged in, skipp login
            return Promise<Void> { fulfill, reject in
                fulfill(())
            }
        }
        return NarProvider.shared.request(.userLogon(login: login, password: password))
            .then { (logonData: UserLogon) -> Void in
                app.dataStore.logonData = logonData
                print("Logged in \(logonData.login)")
        }
    }

    static func loadDefaultDevices() -> Promise<Void> {
        let app = (NSApp.delegate as! AppDelegate)
        if app.dataStore.logonData != nil {
            return NarProvider.shared.request(.sensorsNearby(my: true))
                .then { (near: SensorsNearby) -> Promise<(UserFavorites, SensorsNearby)> in
                    NarProvider.shared.request(.userFavorites).then { ($0, near) }
                }
                .then { (favorites, near) -> Void in
                    var sensorsIds: [Int] = []
                    for device in near.devices {
                        app.dataStore.selectedDevices.append(device.id)
                        if (device.my ?? 0) == 1 {
                            // All sensors from my device
                            device.sensors.forEach { sensorsIds.append($0.id) }
                        }
                    }
                    favorites.sensors.forEach { sensorsIds.append($0.id) }             // Add favorited sensors
                    app.dataStore.selectedWindowSensors = sensorsIds
                    app.dataStore.selectedBarSensors = [Int](sensorsIds.prefix(4))  // Only first 4
                }
        } else {
            return NarProvider.shared.request(.sensorsNearby(my: false))
                // get near
                .then { (near: SensorsNearby) -> Void in
                    guard !near.devices.isEmpty else { throw NarodNetworkError.responceSyntaxError(message: "SensorsNearby")}
                    let devices = near.devices.prefix(2)
                    var sensorsIds: [Int] = []
                    for device in devices {
                        app.dataStore.selectedDevices.append(device.id)
                        device.sensors.forEach { sensorsIds.append($0.id) }
                    }
                    app.dataStore.selectedWindowSensors = sensorsIds
                    app.dataStore.selectedBarSensors = [Int](sensorsIds.prefix(4))  // Only first 4
                }
        }
    }

    /// Load device and sensors definitions (location, name, etc)
    ///
    /// - Returns: void Promise
    static func loadDevicesDefinitions() -> Promise<Void>{
        let app = (NSApp.delegate as! AppDelegate)
        let promises = app.dataStore.selectedDevices.map { deviceId -> Promise<SensorsOnDevice> in
            NarProvider.shared.request(.sensorsOnDevice(id: deviceId)) }
        return when(fulfilled: promises)
            .then { devices in
                app.dataStore.devices = devices
        }
    }
    
    /// Load device data and start refreh
    static func refreshSensorsData() {
        let app = (NSApp.delegate as! AppDelegate)
        var sensors = app.dataStore.selectedBarSensors
        if app.popoverShowed {
            sensors.append(contentsOf: app.dataStore.selectedWindowSensors)
        }
        NarProvider.shared.request(.sensorsValues(sensorIds: sensors))
            .then { (sensorsValues: SensorsValues) -> Void in
                app.dataStore.sensorValue = sensorsValues.sensors
                app.displaySensorData()
            }
            .catch { (error) in
                // Just do nothing
                print(error)
        }
    }
    
    /// Load and display data every N min
    static func startRefreshCycle() {
        let app = (NSApp.delegate as! AppDelegate)
        if let timer = app.sensorsRefreshTimer {
            timer.invalidate()
        }
        app.sensorsRefreshTimer = Timer.scheduledTimer(withTimeInterval: REFRESH_TIME_INTERVAL, repeats: true) {_ in
            self.refreshSensorsData()
        }

    }
}
