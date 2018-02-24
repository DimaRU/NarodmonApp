//
//  DeviceCellView.swift
//  narodmon-bar
//
//  Created by Dmitriy Borovikov on 04.12.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class DeviceCellView: NSTableCellView {

    @IBOutlet weak var deviceLocationLabel: NSTextField?
    @IBOutlet weak var deviceNameLabel: NSTextField?
    @IBOutlet weak var deviceIdLabel: NSTextField?
    
    func setContent(device: SensorsOnDevice) {
        deviceLocationLabel?.stringValue = device.location
        deviceNameLabel?.stringValue = device.name
        deviceIdLabel?.stringValue = String(device.id)
    }
    
}
