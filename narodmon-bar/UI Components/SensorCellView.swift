//
//  SensorCellView.swift
//  narodmon-bar
//
//  Created by Dmitriy Borovikov on 04.12.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class SensorCellView: NSTableCellView {

    var sensor: Sensor!
    
    @IBOutlet weak var sensorNameLabel: NSTextField!
    @IBOutlet weak var sensorValueLabel: NSTextField!
    
    func setContent(sensor: Sensor, value: String, color: NSColor?) {
        sensorNameLabel.stringValue = sensor.name
        sensorValueLabel.stringValue = value
        sensorValueLabel.textColor = color ?? NSColor.controlTextColor
        self.sensor = sensor
    }
    
    @IBAction func openChartAction(_ sender: NSMenuItem) {
        let id = sender.identifier!.rawValue
        let historyPeriod = HistoryPeriod(rawValue: id)!
        let app = NSApp.delegate as! AppDelegate
        nextTick {
            app.sensorsViewController.openChart(cellView: self, sensor: self.sensor, historyPeriod: historyPeriod)
        }
    }
    
}
