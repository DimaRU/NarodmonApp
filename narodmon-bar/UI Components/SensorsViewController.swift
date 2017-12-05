//
//  SensorsViewController.swift
//  narodmon-bar
//
//  Created by Dmitriy Borovikov on 28.11.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class SensorsViewController: NSViewController {

    @IBOutlet weak var toolbarView: NSView!
    @IBOutlet var settingsMenu: NSMenu!
    @IBOutlet weak var sensorsTableView: NSTableView!
    
    @IBAction func settingsButtonPressed(_ sender: NSButton) {
        let p = NSPoint(x: 0, y: sender.frame.height)
        settingsMenu.popUp(positioning: nil, at: p, in: sender)

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbarView.wantsLayer = true
        toolbarView.layer?.backgroundColor = sensorsTableView.backgroundColor.cgColor
        // Do view setup here.
    }

}

extension SensorsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 10
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if row % 2 == 0 {
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DeviceCell"), owner: self) as? DeviceCellView
                else { return nil }
            cell.deviceLocationLabel.stringValue = "Location"
            cell.deviceNameLabel.stringValue = "ID_0000"
            return cell
        } else {
            guard let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SensorCell"), owner: self) as? SensorCellView
                else { return nil }
            cell.sensorNameLabel.stringValue = "Temp"
            cell.sensorValueLabel.stringValue = "33℃"
            return cell
        }
    }
}

extension SensorsViewController: NSTableViewDelegate {
    
}
