//
//  SensorCellView.swift
//  narodmon-bar
//
//  Created by Dmitriy Borovikov on 04.12.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class SensorCellView: NSTableCellView {

    @IBOutlet weak var sensorNameLabel: NSTextField!
    @IBOutlet weak var sensorValueLabel: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func setContent(sensor: Sensor) {
        sensorNameLabel.stringValue = sensor.name!
        sensorValueLabel.stringValue = "\(sensor.value)\(sensor.unit!)"
    }
}
