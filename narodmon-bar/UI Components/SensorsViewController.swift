//
//  SensorsViewController.swift
//  narodmon-bar
//
//  Created by Dmitriy Borovikov on 28.11.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults

class SensorsViewController: NSViewController {
    
    private var devicesSensorsList: [Any] = []
    private var deviceListObserver: NotificationObserver?
    private var dataObserver: NotificationObserver?
    private var popupSensorsObserver: NotificationObserver?
    private var deviceCellStyle = 0
    private let deviceCellId = ["DeviceCell1", "DeviceCell2", "DeviceCell3"]
    
    weak var dataStore: AppDataStore!

    @IBOutlet weak var toolbar: NSView!
    @IBOutlet weak var toolbarTitle: NSTextField!
    @IBOutlet var settingsMenu: NSMenu!
    @IBOutlet weak var closeButton: NSButton!
    
    @IBOutlet weak var sensorsTableView: NSTableView!
    @IBOutlet weak var sensorsScrollView: NSScrollView!
    
    @IBAction func settingsButtonPressed(_ sender: NSButton) {
        let p = NSPoint(x: sender.frame.width/2, y: sender.frame.height/2+4)
        nextTick {
            self.settingsMenu.popUp(positioning: nil, at: p, in: sender)
        }
    }
    
    @IBAction func closeButtonPressed(_ sender: NSButton) {
        closeButton.isHidden = true
        let app = (NSApp.delegate as! AppDelegate)
        app.popover?.close()
    }
    
    override func viewDidLoad() {
        deviceCellStyle = Defaults[.DeviceCellStyle]
        if deviceCellStyle >= deviceCellId.count {
            deviceCellStyle = 0
        }
        devicesSensorsList = dataStore.windowSelectionsList()
        setToolbarTitle()
    }

//    public func windowDidDetach() {
//        closeButton.isHidden = false
//        setViewSizeOnContent()
//    }
//
    public func windowWillShow() {
        addObservers()
        reloadData()
        setViewSizeOnContent()
    }
    
    public func windowWillClose() {
        deviceListObserver = nil
        dataObserver = nil
        popupSensorsObserver = nil
    }

    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let tabViewController = segue.destinationController as? SettingsTabViewController {
            tabViewController.dataStore = dataStore
        }
        super.prepare(for: segue, sender: sender)
    }
    
    private func addObservers() {
        dataObserver = NotificationObserver(forName: .dataChangedNotification) {
            self.sensorsTableView.reloadData()
            self.setToolbarTitle()
            print("Update data")
        }
        deviceListObserver = NotificationObserver(forName: .deviceListChangedNotification) {
            self.reloadData()
            self.setToolbarTitle()
            self.setViewSizeOnContent()
        }
        popupSensorsObserver = NotificationObserver(forName: .popupSensorsChangedNotification) {
            self.reloadData()
            self.setToolbarTitle()
            self.setViewSizeOnContent()
        }
    }
    
    private func setToolbarTitle() {
        guard !devicesSensorsList.isEmpty else {
            let bundleName = Bundle.main.localizedInfoDictionary?["CFBundleName"] as? String
            toolbarTitle.stringValue = bundleName ?? Bundle.main.infoDictionary!["CFBundleName"] as! String
            return
        }
        let lastUpdateTime = dataStore.lastUpdate()
        let interval = -Int(lastUpdateTime.timeIntervalSinceNow)
        print(lastUpdateTime, interval)
        let updateString = NSLocalizedString("Last update: ", comment: "last update in title bar")
        toolbarTitle.stringValue = updateString + DateFormatter.localizedString(from: lastUpdateTime, dateStyle: .none, timeStyle: .short)
    }
    
    func setViewSizeOnContent() {
        nextTick {
            let size = CGSize(width: self.view.frame.size.width, height: self.sensorsTableView.fittingSize.height + self.toolbar.frame.size.height)
            self.preferredContentSize = size
        }
    }

    private func reloadData() {
        devicesSensorsList = dataStore.windowSelectionsList()
        sensorsTableView.reloadData()
    }
}

extension SensorsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return devicesSensorsList.isEmpty ? 1 : devicesSensorsList.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard !devicesSensorsList.isEmpty else {
            return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageCell"), owner: self)
        }
        switch devicesSensorsList[row] {
        case let device as SensorsOnDevice:
            let cellId = deviceCellId[deviceCellStyle]
            guard let deviceCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), owner: self) as? DeviceCellView
                else { return nil }
            deviceCell.setContent(device: device)
            return deviceCell
        case let sensor as Sensor:
            guard let sensorCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SensorCell"), owner: self) as? SensorCellView
                else { return nil }
            if let (value, unit, color) = dataStore.sensorData(for: sensor.id) {
                sensorCell.setContent(sensor: sensor, value: value, unit: unit, color: color)
                return sensorCell
            }
            return nil
        default: fatalError()
        }
    }
}

extension SensorsViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if devicesSensorsList[row] is SensorsOnDevice {
            deviceCellStyle = deviceCellId.nextIndex(deviceCellStyle)
            Defaults[.DeviceCellStyle] = deviceCellStyle
            sensorsTableView.reloadData()
            setViewSizeOnContent()
        }
        return false
    }
}
