//
//  PopupViewController.swift
//  narodmon-bar
//
//  Created by Dmitriy Borovikov on 28.11.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults

class PopupViewController: NSViewController {
    
    private var tableData: [Any] = []
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
        prepareTableData()
        setToolbarTitle()
        sensorsTableView.doubleAction = #selector(cellDobleClicked)
    }

    private func prepareTableData() {
        let popupList = dataStore.windowSelectionsList()
        if popupList.isEmpty {
            tableData = ["MessageCell"]
        } else {
            tableData = popupList
        }
        if !dataStore.webcams.isEmpty {
            tableData.append(contentsOf: dataStore.webcams.sorted{ $0.name < $1.name })
        }
        if checkAppUpdate() {
            tableData.append("FooterCell")
        }
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
        if let lastUpdateTime = dataStore.lastUpdate() {
            let updateString = NSLocalizedString("Last update: ", comment: "last update in title bar")
            toolbarTitle.stringValue = updateString + DateFormatter.localizedString(from: lastUpdateTime, dateStyle: .none, timeStyle: .short)
        } else {
            let bundleName = Bundle.main.localizedInfoDictionary?["CFBundleName"] as? String
            toolbarTitle.stringValue = bundleName ?? Bundle.main.infoDictionary!["CFBundleName"] as! String
        }
    }
    
    func setViewSizeOnContent() {
        sensorsScrollView.hasVerticalScroller = false
        nextTick {
            let heigh = self.sensorsTableView.fittingSize.height + self.toolbar.frame.size.height + self.bottomPadConstraint.constant
            self.preferredContentSize = CGSize(width: self.view.frame.size.width, height: heigh)
        }
    }

    private func reloadData() {
        prepareTableData()
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
        present(chartViewController, asPopoverRelativeTo: .zero, of: cellView, preferredEdge: .minX, behavior: .transient)
    }

    func openWebcamView(cellView: NSView, webcam: WebcamImages) {
        let webcamViewController = WebcamViewController.instance()
        webcamViewController.webcam = webcam
        present(webcamViewController, asPopoverRelativeTo: .zero, of: cellView, preferredEdge: .minX, behavior: .transient)
    }

    // MARK: Menu actions
    @IBAction func nextDeviceViewAction(_ sender: NSMenuItem) {
        nextDeviceView()
    }
    
    // MARK: Double click actions
    @objc private func cellDobleClicked(_ sender: Any) {
        switch tableData[sensorsTableView.clickedRow] {
        case is String:
            return
        case is SensorsOnDevice:
            nextDeviceView()
        case let sensor as Sensor:
            let cellView = sensorsTableView.view(atColumn: 0, row: sensorsTableView.clickedRow, makeIfNecessary: false)!
            openChart(cellView: cellView, sensor: sensor, historyPeriod: .day)
        case let webcam as WebcamImages:
            print(webcam.id!)
            let cellView = sensorsTableView.view(atColumn: 0, row: sensorsTableView.clickedRow, makeIfNecessary: false)!
            openWebcamView(cellView: cellView, webcam: webcam)
        default: fatalError()
        }
    }
}

extension PopupViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return tableData.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if row == tableView.numberOfRows - 1 {
            // last row
            setViewSizeOnContent()
        }
        
        switch tableData[row] {
        case let cellId as String:
            return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), owner: self)
        case let device as SensorsOnDevice:
            let cellId = deviceCellId[deviceCellStyle]
            let deviceCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), owner: self) as? DeviceCellView
            deviceCell?.setContent(device: device)
            return deviceCell
        case let sensor as Sensor:
            let sensorCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SensorCell"), owner: self) as? SensorCellView
            guard let (value, color) = dataStore.sensorData(for: sensor.id, format: .medium) else { return nil }
            sensorCell?.setContent(sensor: sensor, value: value, color: color)
            return sensorCell
        case let webcam as WebcamImages:
            let webcamCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "WebcamCell"), owner: self) as? WebcamCellView
            webcamCell?.setContent(webcam: webcam)
            return webcamCell
        default: fatalError()
        }
    }
}

extension PopupViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
}
