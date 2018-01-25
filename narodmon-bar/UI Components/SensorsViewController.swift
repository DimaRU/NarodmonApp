//
//  SensorsViewController.swift
//  narodmon-bar
//
//  Created by Dmitriy Borovikov on 28.11.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class SensorsViewController: NSViewController {
    
    private var devicesSensorsList: [Any] = []
    var dataStore: AppDataStore!

    @IBOutlet weak var toolbar: NSBox!
    @IBOutlet var settingsMenu: NSMenu!
    @IBOutlet weak var closeButton: NSButton!
    
    @IBOutlet weak var sensorsTableView: NSTableView!
    @IBOutlet weak var sensorsScrollView: NSScrollView!
    
    @IBAction func settingsButtonPressed(_ sender: NSButton) {
        let p = NSPoint(x: 0, y: sender.frame.height)
        settingsMenu.popUp(positioning: nil, at: p, in: sender)
    }
    
    @IBAction func closeButtonPressed(_ sender: NSButton) {
        closeButton.isHidden = true
        let app = (NSApp.delegate as! AppDelegate)
        app.detachedWindow?.close()
        app.detachedWindow?.contentViewController = nil
    }
    
    override func viewDidLoad() {
        devicesSensorsList = dataStore.windowSelectionsList()
        addObservers()
    }

    public func windowDidDetach() {
        print("Detach...")
        closeButton.isHidden = false
        setViewSizeOnContent()
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let tabViewController = segue.destinationController as? SettingsTabViewController {
            tabViewController.dataStore = dataStore
        }
        super.prepare(for: segue, sender: sender)
    }
    
    private func addObservers() {
        let center = NotificationCenter.default
        center.addObserver(forName: .dataChangedNotification, object: nil, queue: nil) { _ in
            self.sensorsTableView.reloadData()
            
        }
        center.addObserver(forName: .deviceListChangedNotification, object: nil, queue: nil) { _ in
            self.reloadData()
            self.setViewSizeOnContent()
        }
        center.addObserver(forName: .popupSensorsChangedNotification, object: nil, queue: nil) { _ in
            self.reloadData()
            self.setViewSizeOnContent()
        }
    }
    
    func setViewSizeOnContent() {
        let dHeight = sensorsTableView.frame.size.height + toolbar.frame.size.height + 2 - view.frame.size.height

        guard dHeight != 0 else { return }
        var size = view.frame.size
        size.height +=  dHeight
        view.setFrameSize(size)
        
        guard var windowFrame = view.window?.frame else { return }
        windowFrame.size.height += dHeight
        windowFrame.origin.y -= dHeight
        view.window!.setFrame(windowFrame, display: false, animate: false)
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
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
}
