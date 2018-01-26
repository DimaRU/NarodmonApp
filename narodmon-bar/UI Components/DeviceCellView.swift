//
//  DeviceCellView.swift
//  narodmon-bar
//
//  Created by Dmitriy Borovikov on 04.12.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class DeviceCellView: NSTableCellView {

    let bgColor = NSColor(white: 1, alpha: 0.3)
    
    @IBOutlet weak var deviceLocationLabel: NSTextField!
    @IBOutlet weak var deviceNameLabel: NSTextField!
    
    func setContent(device: SensorsOnDevice) {
        deviceLocationLabel.stringValue = device.location
        deviceNameLabel.stringValue = device.name
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.wantsLayer = true
        self.layer?.backgroundColor = bgColor.cgColor
    }
    
}
