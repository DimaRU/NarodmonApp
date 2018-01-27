//
//  DetachedWindow.swift
//  NarodmonBar
//
//  Created by Dmitriy Borovikov on 24.01.2018.
//  Copyright © 2018 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class DetachedWindow: NSWindow {
    override var canBecomeKey: Bool {
        return true
    }
    
    init(frame: NSRect) {
        let styleMask: NSWindow.StyleMask = [NSWindow.StyleMask.borderless]
        let rect = NSWindow.contentRect(forFrameRect: frame, styleMask: styleMask)
        super.init(contentRect: rect, styleMask: styleMask, backing: .buffered, defer: true)

        self.isReleasedWhenClosed = false
        self.isMovableByWindowBackground = true
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
    }

}
