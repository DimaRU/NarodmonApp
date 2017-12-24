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
    
    func setContent(sensor: Sensor, value: Double, unit: String) {
        sensorNameLabel.stringValue = sensor.name
        sensorValueLabel.stringValue = "\(value)\(unit)"
    }
}
