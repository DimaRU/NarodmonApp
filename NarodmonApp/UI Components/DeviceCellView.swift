//
//  DeviceCellView.swift
//  NarodmonApp
//
//  Created by Dmitriy Borovikov on 04.12.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class DeviceCellView: NSTableCellView {

    var deviceId: Int!
    
    @IBOutlet weak var deviceLocationLabel: NSTextField?
    @IBOutlet weak var deviceNameLabel: NSTextField?
    @IBOutlet weak var deviceIdLabel: NSTextField?
    
    func setContent(device: SensorsOnDevice) {
        deviceLocationLabel?.stringValue = device.location
        deviceNameLabel?.stringValue = device.name
        deviceIdLabel?.stringValue = String(device.id)
        deviceId = device.id
    }
    
    @IBAction func viewInMapAction(_ sender: NSMenuItem) {
        let baseUrl = NSLocalizedString("https://narodmon.com", comment: "Open map URL")
        NSWorkspace.shared.open(URL(string: baseUrl + "/" + String(deviceId))!)
    }
}
