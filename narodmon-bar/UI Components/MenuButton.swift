////
///  MenuButton.swift
//
//  Thanks Jonathan Mitchell https://stackoverflow.com/a/21007436/7666732

import Cocoa

class MenuButton: NSButton {

    override func mouseDown(with event: NSEvent) {
        // if a menu is defined let the cell handle its display
        if menu != nil {
            if event.type == .leftMouseDown {
                cell?.menu = menu
            }
            else {
                cell?.menu = nil
            }
        }
        super.mouseDown(with: event)
    }
}


class MenuButtonCell: NSButtonCell {
    override func trackMouse(with event: NSEvent, in cellFrame: NSRect, of controlView: NSView, untilMouseUp flag: Bool) -> Bool {
        // if menu defined show on left mouse
        if event.type == .leftMouseDown && menu != nil {
            let menuLocation: NSPoint = controlView.convert(NSMakePoint(NSMidX(cellFrame), NSMaxY(cellFrame)), to: nil)
            if let newEvent = NSEvent.mouseEvent(with: event.type, location: menuLocation, modifierFlags: event.modifierFlags, timestamp: event.timestamp, windowNumber: event.windowNumber, context: nil, eventNumber: event.eventNumber, clickCount: event.clickCount, pressure: event.pressure) {
            // need to generate a new event otherwise selection of button
            // after menu display fails
                NSMenu.popUpContextMenu(menu!, with: newEvent, for: controlView)
            }
            return true
        }
        return super.trackMouse(with: event, in: cellFrame, of: controlView, untilMouseUp: flag)
    }

}
