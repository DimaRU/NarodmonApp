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
    private var chartPopover: NSPopover? = nil
    
    weak var dataStore: AppDataStore!

    @IBOutlet weak var toolbar: NSView!
    @IBOutlet weak var toolbarTitle: NSTextField!
    @IBOutlet var settingsMenu: NSMenu!
    @IBOutlet weak var closeButton: NSButton!
    
    @IBOutlet weak var sensorsTableView: NSTableView!
    @IBOutlet weak var sensorsScrollView: NSScrollView!
    @IBOutlet weak var bottomPadConstraint: NSLayoutConstraint!
    
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
        sensorsTableView.doubleAction = #selector(cellDobleClicked)
    }

    public func windowDidDetach() {
        closeButton.isHidden = false
    }

    public func windowWillShow() {
        addObservers()
        reloadData()
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
        }
        deviceListObserver = NotificationObserver(forName: .deviceListChangedNotification) {
            self.reloadData()
        }
        popupSensorsObserver = NotificationObserver(forName: .popupSensorsChangedNotification) {
            self.reloadData()
        }
    }
    
    private func setToolbarTitle() {
        guard !devicesSensorsList.isEmpty else {
            let bundleName = Bundle.main.localizedInfoDictionary?["CFBundleName"] as? String
            toolbarTitle.stringValue = bundleName ?? Bundle.main.infoDictionary!["CFBundleName"] as! String
            return
        }
        let lastUpdateTime = dataStore.lastUpdate()
        let updateString = NSLocalizedString("Last update: ", comment: "last update in title bar")
        toolbarTitle.stringValue = updateString + DateFormatter.localizedString(from: lastUpdateTime, dateStyle: .none, timeStyle: .short)
    }
    
    func setViewSizeOnContent() {
        sensorsScrollView.hasVerticalScroller = false
        nextTick {
            let heigh = self.sensorsTableView.fittingSize.height + self.toolbar.frame.size.height + self.bottomPadConstraint.constant
            self.preferredContentSize = CGSize(width: self.view.frame.size.width, height: heigh)
        }
    }

    private func reloadData() {
        devicesSensorsList = dataStore.windowSelectionsList()
        sensorsTableView.reloadData()
        setToolbarTitle()
    }
    
    func nextDeviceView() {
        deviceCellStyle = deviceCellId.nextIndex(deviceCellStyle)
        Defaults[.DeviceCellStyle] = deviceCellStyle
        sensorsTableView.reloadData()
    }
    
    func openChart(cellView: NSView, sensor: Sensor, historyPeriod: HistoryPeriod) {
        let chartViewController = ChartViewController.instance()
        chartViewController.sensor = sensor
        chartViewController.dataStore = dataStore
        chartViewController.historyPeriod = historyPeriod
        presentViewController(chartViewController, asPopoverRelativeTo: .zero, of: cellView, preferredEdge: .minX, behavior: .transient)
    }

    // MARK: Menu actions
    @IBAction func nextDeviceViewAction(_ sender: NSMenuItem) {
        nextDeviceView()
    }
    
    // MARK: Double click actions
    @objc private func cellDobleClicked(_ sender: Any) {
        guard sensorsTableView.clickedRow < devicesSensorsList.count else {
            // Footer row clicked
            return
        }
        switch devicesSensorsList[sensorsTableView.clickedRow] {
        case is SensorsOnDevice:
            nextDeviceView()
        case let sensor as Sensor:
            let cellView = sensorsTableView.view(atColumn: 0, row: sensorsTableView.clickedRow, makeIfNecessary: false)!
            openChart(cellView: cellView, sensor: sensor, historyPeriod: .day)
        default: fatalError()
        }
    }
}

extension SensorsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        var rows = devicesSensorsList.count
        if devicesSensorsList.isEmpty {
            rows += 1
        }
        if dataStore.initData?.latest != appVersion() {
            // Footer
            rows += 1
        }
        return rows
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if row == tableView.numberOfRows - 1 {
            // last row
            setViewSizeOnContent()
        }
        
        if devicesSensorsList.isEmpty && row == 0 {
            return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MessageCell"), owner: self)
        }
        guard row < devicesSensorsList.count else {
            return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FooterCell"), owner: self)
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
        return false
    }
}
