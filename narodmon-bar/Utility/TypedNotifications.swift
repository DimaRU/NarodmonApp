////
///  TypedNotifications.swift
//
//  Thanks to objc.io http://www.objc.io/snippets/16.html
//  Find Here: https://gist.github.com/chriseidhof/9bf7280063db3a249fbe

import Foundation

func postNotification(name: Notification.Name) {
    NotificationCenter.default.post(name: name, object: nil)
}

class NotificationObserver {
    let observer: NSObjectProtocol

    init(forName: Notification.Name, block aBlock: @escaping () -> Void) {
        observer = NotificationCenter.default.addObserver(forName: forName, object: nil, queue: nil) { note in
            aBlock()
        }
    }

    func removeObserver() {
        NotificationCenter.default.removeObserver(observer)
    }

    deinit {
        removeObserver()
    }

}
