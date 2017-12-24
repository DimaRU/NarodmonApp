//
//  PrefsCell.swift
//  TestTabView
//
//  Created by Dmitriy Borovikov on 14.12.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class PrefsCell: NSTableCellView {

    @IBOutlet weak var checkBox: NSButton?
    @IBOutlet weak var sensorNameLabel: NSTextField!
    @IBOutlet weak var sensorValueLabel: NSTextField!
    
    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(frame, cursor: NSCursor.openHand)
        if let checkBox = checkBox {
            addCursorRect(checkBox.frame, cursor: NSCursor.pointingHand)
        }
    }
    
    func setContent(sensor: Sensor) {
        sensorNameLabel.stringValue = sensor.name
        sensorValueLabel.stringValue = "\(sensor.value)\(sensor.unit)"
    }
}
