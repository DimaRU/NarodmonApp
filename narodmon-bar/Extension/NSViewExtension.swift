//
//  NSViewExtension.swift
//  testUI1
//
//  Created by Dmitriy Borovikov on 25.04.17.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

extension NSView {
    var backgoundColor: NSColor {
        get {
            return NSColor(cgColor: (self.layer?.backgroundColor)!)!
        }
        set {
            self.layer?.backgroundColor = newValue.cgColor
        }
    }
}

extension NSView {
    class func fromNib<T: NSView>() -> T? {
        var viewArray: NSArray? = NSArray()
        guard Bundle.main.loadNibNamed(NSNib.Name(rawValue: String(describing: T.self)),
                                       owner: nil,
                                       topLevelObjects: &viewArray) else {
            return nil
        }
        return viewArray?.first(where: { $0 is T }) as? T
    }
}
