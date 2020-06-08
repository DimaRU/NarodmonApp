////
///  HwUUID.swift
//

import Cocoa
import IOKit

// Hardare UUID shows in the system profiler.
func getHwUUID() -> String {
    var uuidBytes: [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    var ts = timespec(tv_sec: 0,tv_nsec: 0)
    
    gethostuuid(&uuidBytes, &ts)
    return NSUUID(uuidBytes: uuidBytes).uuidString
}
