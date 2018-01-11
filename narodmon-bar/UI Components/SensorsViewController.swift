//
//  SensorsViewController.swift
//  narodmon-bar
//
//  Created by Dmitriy Borovikov on 28.11.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class SensorsViewController: NSViewController {
    
    var devicesSensorsList: [Any] = []
    lazy var dataStore = (NSApp.delegate as! AppDelegate).dataStore

    @IBOutlet weak var toolbar: NSBox!
    @IBOutlet var settingsMenu: NSMenu!
    
    @IBOutlet weak var sensorsTableView: NSTableView!
    @IBOutlet weak var sensorsScrollView: NSScrollView!
    
    @IBAction func settingsButtonPressed(_ sender: NSButton) {
        let p = NSPoint(x: 0, y: sender.frame.height)
        settingsMenu.popUp(positioning: nil, at: p, in: sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reloadData()
        setViewSizeOnContent()
        addObservers()
    }
    
    private func addObservers() {
        let center = NotificationCenter.default
        center.addObserver(forName: .dataChangedNotification, object: nil, queue: nil) { _ in
            self.sensorsTableView.reloadData()
        }
        center.addObserver(forName: .deviceListChangedNotification, object: nil, queue: nil) { _ in
            self.reloadData()
        }
        center.addObserver(forName: .popupSensorsChangedNotification, object: nil, queue: nil) { _ in
            self.reloadData()
        }
    }
    
    public func windowDidDetach() {
        print("On detach:", self.view.frame.size.height)
    }

    private func setViewSizeOnContent() {
        var size = view.frame.size
        size.height = sensorsScrollView.documentView!.frame.size.height + toolbar.frame.size.height + 2
        view.setFrameSize(size)
    }

    private func reloadData() {
        devicesSensorsList = dataStore.windowSelectionsList()
        sensorsTableView.reloadData()
    }
}


extension SensorsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return devicesSensorsList.count
    }
    
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        return devicesSensorsList[row] is SensorsOnDevice
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch devicesSensorsList[row] {
        case let device as SensorsOnDevice:
            guard let deviceCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DeviceCell"), owner: self) as? DeviceCellView
                else { return nil }
            deviceCell.setContent(device: device)
            return deviceCell
        case let sensor as Sensor:
            guard let sensorCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SensorCell"), owner: self) as? SensorCellView
                else { return nil }
            if let (value, unit) = dataStore.sensorData(for: sensor.id) {
                sensorCell.setContent(sensor: sensor, value: value, unit: unit)
                return sensorCell
            }
            return nil
        default: fatalError()
        }
    }
}

extension SensorsViewController: NSTableViewDelegate {
    
}
