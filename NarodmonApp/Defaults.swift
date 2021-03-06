////
///  Defaults.swift
//

import Cocoa

extension UserDefaults {
    subscript(key: DefaultsKey<NSColor?>) -> NSColor? {
        get { return unarchive(key) }
        set { archive(key, newValue) }
    }
}

extension DefaultsKeys {
    static let Launchcount = DefaultsKey<Int>("LaunchCount")
    static let LaunchOnLogin = DefaultsKey<Bool>("LaunchOnLogin")
    static let MachineUUID = DefaultsKey<String?>("MachineUUID")
    
    static let SelectedDevices = DefaultsKey<[Int]>("SelectedDevices")
    static let SelectedWindowSensors = DefaultsKey<[Int]>("SelectedWindowSensors")
    static let SelectedBarSensors = DefaultsKey<[Int]>("SelectedBarSensors")
    static let SelectedWebcams = DefaultsKey<[Int]>("SelectedWebcams")
    static let SensorsMin = DefaultsKey<[String: Any]>("SensorsMin")
    static let SensorsMax = DefaultsKey<[String: Any]>("SensorsMax")
    static let ColorMin = DefaultsKey<NSColor?>("ColorMin")
    static let ColorMax = DefaultsKey<NSColor?>("ColorMax")
    static let TinyFont = DefaultsKey<Bool>("TinyFont")
    static let DeviceCellStyle = DefaultsKey<Int>("DeviceCellStyle")
    static let AlwaysOnTop = DefaultsKey<Bool>("AlwaysOnTop")
}


extension UserDefaults {
    /// Inital setup when App Started
    public func appStart() {
        Defaults[.Launchcount] += 1
        
        if Defaults[.MachineUUID] == nil {
            // First start
            let uuid = getHwUUID().md5()
            Defaults[.MachineUUID] = uuid

            setLaunchOnLogin(state: true)
            Defaults[.LaunchOnLogin] = true
        } else {
            // Not first start
        }
#if DEBUG
        dumpDefaults()
#endif
    }
    
#if DEBUG
    private func dumpDefaults() {
        print("------- Defaults dump start")
        dumpDefault(.Launchcount)
        dumpDefault(.MachineUUID)
        dumpDefault(.SelectedDevices)
        dumpDefault(.SelectedWindowSensors)
        dumpDefault(.SelectedBarSensors)
        dumpDefault(.SelectedWebcams)
        dumpDefault(.SensorsMin)
        dumpDefault(.SensorsMax)
        print("------- Defaults dump end")
    }
    
    private func dumpDefault(_ defaultsKey: DefaultsKey<Int> ) { print("\(defaultsKey._key):", Defaults[defaultsKey]) }
    private func dumpDefault(_ defaultsKey: DefaultsKey<[Int]> ) { print("\(defaultsKey._key):", Defaults[defaultsKey]) }
    private func dumpDefault(_ defaultsKey: DefaultsKey<Bool> ) { print("\(defaultsKey._key):", Defaults[defaultsKey]) }
    private func dumpDefault(_ defaultsKey: DefaultsKey<[String]> ) { print("\(defaultsKey._key):", Defaults[defaultsKey]) }
    private func dumpDefault(_ defaultsKey: DefaultsKey<[String: Any]> ) { print("\(defaultsKey._key):", Defaults[defaultsKey]) }
    private func dumpDefault(_ defaultsKey: DefaultsKey<String?> ) {
        guard Defaults[defaultsKey] != nil else { return }
        print("\(defaultsKey._key):", Defaults[defaultsKey]!)
    }
#endif

    public func selectionExist() -> Bool {
        return !Defaults[.SelectedDevices].isEmpty && !Defaults[.SelectedBarSensors].isEmpty
    }
}
