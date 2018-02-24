//
//  PrefsCellView.swift
//  TestTabView
//
//  Created by Dmitriy Borovikov on 14.12.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class PrefsCellView: NSTableCellView {

    @IBOutlet weak var checkBox: NSButton?
    @IBOutlet weak var sensorNameLabel: NSTextField!
    @IBOutlet weak var sensorValueLabel: NSTextField!
    
    override func resetCursorRects() {
        discardCursorRects()
        if let checkBox = checkBox {
            addCursorRect(checkBox.frame, cursor: NSCursor.pointingHand)
        } else {
            addCursorRect(frame, cursor: NSCursor.openHand)
        }
    }
   
    func setContent(sensor: Sensor, isChecked: Bool) {
        sensorNameLabel.stringValue = sensor.name
        sensorValueLabel.stringValue = "\(sensor.value)\(sensor.unit)"
        checkBox?.state = isChecked ? .on : .off
        checkBox?.tag = sensor.id
    }
}
