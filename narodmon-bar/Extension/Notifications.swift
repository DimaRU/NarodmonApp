////
///  Notifications.swift
//

import Foundation

extension Notification.Name {
    
    static let dataChangedNotification = Notification.Name(rawValue: "dataChanged")
    static let deviceListChangedNotification = Notification.Name(rawValue: "deviceListChanged")
    static let barSensorsChangedNotification = Notification.Name(rawValue: "barSensorsChanged")
    static let popupSensorsChangedNotification = Notification.Name(rawValue: "popupSensorsChanged")
}
