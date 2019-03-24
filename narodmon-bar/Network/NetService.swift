////
///  InitService.swift
//

import Cocoa
import PromiseKit

struct NetService {

    static func appInit() -> Promise<AppInitData> {
        let version = appVersion()
        let system = ProcessInfo.processInfo.operatingSystemVersion
        let platform = "\(system.minorVersion).\(system.patchVersion)"
        let model = Sysctl.model
        let utc = TimeZone.current.secondsFromGMT() / 3600
        
        return NarProvider.shared.request(.appInit(version: version, platform: platform, model: model, timeZone: utc))
    }
    
    static func appLogin() -> Promise<Void> {
        guard let login = KeychainService.shared[.login], let password = KeychainService.shared[.password] else {
            return Promise.value(())
        }
        let app = (NSApp.delegate as! AppDelegate)
        let initData = app.dataStore.initData!
        if Int(initData.uid) != 0 {
            let logonData = UserLogon(vip: initData.vip, login: initData.login, uid: initData.uid)
            app.dataStore.logonData = logonData
            // Already logged in, skip login
            return Promise.value(())
        }
        return NarProvider.shared.request(.userLogon(login: login, password: password))
            .done { (logonData: UserLogon) -> Void in
                app.dataStore.logonData = logonData
        }
    }

    /// Add own devices & sensors to list when login
    ///
    /// - Returns: void Promise
    static func appLoginDiscovery() -> Promise<Void> {
        let login = KeychainService.shared[.login]!
        let password = KeychainService.shared[.password]!
        let app = (NSApp.delegate as! AppDelegate)

        return NarProvider.shared.request(.userLogout)
            .then { (logoutData: UserLogout) -> Promise<UserLogon> in
                return NarProvider.shared.request(.userLogon(login: login, password: password))
            }
            .then { (logonData: UserLogon) -> Promise<SensorsNearby> in
                app.dataStore.logonData = logonData
                return NarProvider.shared.request(.sensorsNearby(my: true))
            }
            .done { (near: SensorsNearby) -> Void in
                for i in near.devices.indices {
                    let device = near.devices[i]
                    if !app.dataStore.selectedDevices.contains(device.id) {
                        app.dataStore.devices.insert(device, at: i)
                        app.dataStore.selectedDevices.insert(device.id, at: i)
                        let sensorsId = device.sensors.map { $0.id }
                        app.dataStore.selectedWindowSensors.append(contentsOf: sensorsId)
                    }
                }
        }
    }

    /// Discovery & add nearest or own devices & sensors to list
    ///
    /// - Returns: void Promise
    static func loadDefaultDevices() -> Promise<Void> {
        let app = (NSApp.delegate as! AppDelegate)
        if app.dataStore.logonData != nil {
            return NarProvider.shared.request(.sensorsNearby(my: true))
                .then { (near: SensorsNearby) -> Promise<(UserFavorites, SensorsNearby)> in
                    NarProvider.shared.request(.userFavorites(webcams: [])).map { ($0, near) }
                }
                .done { (arg) -> Void in
                    let (favorites, near) = arg
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
                .done { (near: SensorsNearby) -> Void in
                    guard !near.devices.isEmpty else { return }
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
    static func loadDevicesDefinitions() -> Promise<Void> {
        let app = (NSApp.delegate as! AppDelegate)
        let selectedDevices = app.dataStore.selectedDevices
        app.lastRequestTime = Date()
        app.dataStore.sensorValues = []    // Invalidate
        
        var promises: [Promise<Void>] = []
        for deviceId in selectedDevices {
            promises.append(
                NarProvider.shared.request(.sensorsOnDevice(id: deviceId))
                    .then { (device: SensorsOnDevice) -> Promise<Void> in
                        app.dataStore.devices.append(device)
                        return Promise.value(())
                    }
                    .recover { (error) -> Promise<Void> in
                        if case NarodNetworkError.accessDenied = error {
                            let e = error as! NarodNetworkError
                            e.displayAlert()
                            return Promise.value(())
                        }
                        throw error
                }
            )
        }
        return when(fulfilled: promises)
    }
    
    /// Load Webcam definitions (location, name )
    ///
    /// - Returns: void Promise
    static func loadWebcamDefinitions() -> Promise<Void> {
        let app = (NSApp.delegate as! AppDelegate)
        let selectedWebcams = app.dataStore.selectedWebcams
        app.lastRequestTime = Date()
        
        var promises: [Promise<Void>] = []
        for webcamId in selectedWebcams {
            promises.append(
                NarProvider.shared.request(.webcamImages(id: webcamId, limit: 1, latest: nil))
                    .done { (webcamImages: WebcamImages) -> Void in
                        app.dataStore.webcams.append(webcamImages)
                        return
                    }
                    .recover { (error) -> Void in
                        switch error {
                        case NarodNetworkError.notFound:
                            break
                        case NarodNetworkError.accessDenied:
                            let e = error as! NarodNetworkError
                            e.displayAlert()
                            return
                        default:
                            throw error
                        }
                }
            )
        }
        return when(fulfilled: promises)
    }

    
    /// Load device data and send notification
    static func loadSensorsData() {
        let app = (NSApp.delegate as! AppDelegate)
        var sensors = Set<Int>(app.dataStore.selectedBarSensors)
        if app.popoverShowed {
            sensors = sensors.union(app.dataStore.selectedWindowSensors)
        }
        guard !sensors.isEmpty else { return }
        
        app.lastRequestTime = Date()
        
        NarProvider.shared.request(.sensorsValues(sensorIds: Array<Int>(sensors)))
            .done { (sensorsValues: SensorsValues) -> Void in
                app.dataStore.sensorValues = sensorsValues.sensors
                postNotification(name: .dataChangedNotification)
            }
            .catch { (error) in
                // Just do nothing
                print(error)
        }
    }
    
    /// Load sensor history
    static func loadSensorHistory(id: Int, period: HistoryPeriod, offset: Int) -> Promise<[SensorHistoryData]> {
        return NarProvider.shared.request(.sensorHistory(id: id, period: period, offset: offset))
            .map { (sensorHistory: SensorHistory) -> [SensorHistoryData] in
                return sensorHistory.data
        }
    }
}
