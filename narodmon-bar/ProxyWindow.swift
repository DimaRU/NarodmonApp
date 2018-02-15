//
//  DetachedWindow.swift
//  NarodmonBar
//
//  Created by Dmitriy Borovikov on 24.01.2018.
//  Copyright © 2018 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class ProxyWindow: NSWindow {
    override var canBecomeKey: Bool {
        return false
    }
    
    init(from window: NSWindow) {
        let styleMask: NSWindow.StyleMask = [NSWindow.StyleMask.borderless]
        let rect = window.frame
        let windowFrame = NSRect(x: rect.minX, y: rect.minY, width: rect.width, height: 1)
        print(rect, windowFrame)
        let contentRect = NSWindow.contentRect(forFrameRect: windowFrame, styleMask: styleMask)
        
        super.init(contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: true)
        
        self.appearance = window.appearance
        self.isReleasedWhenClosed = false
        self.isExcludedFromWindowsMenu = true
        self.isMovableByWindowBackground = false
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.contentView = NSView(frame: NSRect(x: 0, y: 0, width: frame.width, height: 1))
        self.level = .init(25)
    }
}
