//
//  SensorSettingsViewController.swift
//  TestTabView
//
//  Created by Dmitriy Borovikov on 11.12.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults

protocol DeviceIdDelegate {
    func add(device id: Int)
}

class SensorSettingsViewController: NSViewController, DeviceIdDelegate {

    var dataStore: AppDataStore!
    
    private var devicesSensorsList: [Any] = []

    var hasDraggedFavoriteItem = false
    var currentItemDragOperation: NSDragOperation = []
    
    @IBOutlet weak var sensorsTableView: SelectTableView!
    @IBOutlet weak var favoriteTableView: SelectTableView!
    @IBOutlet weak var largeFontCheckBox: NSButton!
    
    @IBAction func checkBoxSensorAction(_ sender: NSButton) {
        let sensorId = sender.tag
        if sender.state == .on {
            dataStore.selectedWindowSensors.append(sensorId)
        }
        else {
            let index = dataStore.selectedWindowSensors.index(where: {$0 == sensorId})!
            dataStore.selectedWindowSensors.remove(at: index)
        }
        NotificationCenter.default.post(name: .popupSensorsChangedNotification, object: nil)
    }
    
    @IBAction func largeFontCheckBoxAction(_ sender: NSButton) {
        let tinyFont: Bool = sender.state == .off
        Defaults[.TinyFont] = tinyFont
        let app = NSApp.delegate as! AppDelegate
        app.statusView.isTinyText = tinyFont
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        guard let viewController = segue.destinationController as? DeviceIDViewCotroller else { return }
        viewController.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sensorsTableView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
        sensorsTableView.setDraggingSourceOperationMask([.move, .delete], forLocal: true)
        favoriteTableView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
        favoriteTableView.setDraggingSourceOperationMask([.move, .delete], forLocal: true)

        largeFontCheckBox.state = Defaults[.TinyFont] ? .off : .on
        devicesSensorsList = dataStore.devicesSensorsList()
        addObservers()
    }
    
    override func viewWillDisappear() {
        dataStore.saveDefaults()
    }
    
    func addObservers() {
        let center = NotificationCenter.default
        center.addObserver(forName: .deviceListChangedNotification, object: nil, queue: nil) {_ in
            self.devicesSensorsList = self.dataStore.devicesSensorsList()
            self.sensorsTableView.reloadData()
            self.favoriteTableView.reloadData()
        }
    }
    
    
    func remove(device: SensorsOnDevice) {
        let sensorIds = Set<Int>(device.sensors.map { $0.id })
        
        dataStore.selectedWindowSensors = dataStore.selectedWindowSensors.filter { !sensorIds.contains($0) }
        dataStore.selectedBarSensors = dataStore.selectedBarSensors.filter { !sensorIds.contains($0) }
        dataStore.selectedDevices = dataStore.selectedDevices.filter{ $0 != device.id }
        let index = dataStore.devices.index(where: {$0.id == device.id})!
        dataStore.devices.remove(at: index)
        
        NotificationCenter.default.post(name: .deviceListChangedNotification, object: nil)
    }
    
    func add(device id: Int) {
        print("Add device:", id)
        guard !dataStore.selectedDevices.contains(id) else {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Add device", comment: "Add device")
            alert.informativeText = NSLocalizedString("Device already added", comment: "Add device")
            alert.runModal()
            return
        }
        
        NarProvider.shared.request(.sensorsOnDevice(id: id))
            .then { (device: SensorsOnDevice) -> Void in
                self.dataStore.devices.append(device)
                self.dataStore.selectedDevices.append(id)
                let sensors: [Int] = device.sensors.map { $0.id }
                self.dataStore.selectedWindowSensors.append(contentsOf: sensors)

                NotificationCenter.default.post(name: .deviceListChangedNotification, object: nil)
            }
            .catch { error in
                guard let error = error as? NarodNetworkError else { fatalError() }
                let alert = NSAlert()
                alert.messageText = error.localizedDescription
                alert.informativeText = error.message()
                alert.runModal()
        }
    }

}




extension  SensorSettingsViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        switch tableView {
        case sensorsTableView:
            return devicesSensorsList.count
        case favoriteTableView:
            return dataStore.selectedBarSensors.count + 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        switch tableView {
        case sensorsTableView:
            return devicesSensorsList[row] is SensorsOnDevice
        case favoriteTableView:
            return row == 0
        default: fatalError()
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch tableView {
            
        case sensorsTableView:
            switch devicesSensorsList[row] {
            case let device as SensorsOnDevice:
                guard let deviceCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DeviceCell"), owner: self) as? DeviceCellView
                    else { return nil }
                deviceCell.setContent(device: device)
                return deviceCell
            case let sensor as Sensor:
                guard let sensorCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SensorCell"), owner: self) as? PrefsCellView
                    else { return nil }
                sensorCell.setContent(sensor: sensor, isChecked: dataStore.selectedWindowSensors.contains(sensor.id))
                return sensorCell
            default: fatalError()
            }

            
        case favoriteTableView:
            if row == 0 {
                return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self)
            } else {
                let id = dataStore.selectedBarSensors[row-1]
                for element in devicesSensorsList {
                    if let sensor = element as? Sensor, sensor.id == id {
                        guard let sensorCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SensorCell"), owner: self) as? PrefsCellView
                            else { return nil }
                        sensorCell.setContent(sensor: sensor, isChecked: false)
                        return sensorCell
                    }
                }
            }
            
        default: fatalError()
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
    
    
    // Mark: Drag-n-drop

    /// Start drag-n-drop
    ///
    /// - Returns: true if drag is allowed
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        let row = rowIndexes.first!

        switch tableView {
        case sensorsTableView:
            hasDraggedFavoriteItem = false
            if devicesSensorsList[row] is SensorsOnDevice {
                hasDraggedFavoriteItem = true
                currentItemDragOperation = .delete
            }
            if let sensor = devicesSensorsList[row] as? Sensor, dataStore.selectedBarSensors.contains(sensor.id) {
                return false
            }
        case favoriteTableView:
            if row == 0 {
                return false
            }
            hasDraggedFavoriteItem = true
        default: fatalError()
        }

        let data = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)
        pboard.declareTypes([NSPasteboard.PasteboardType.string], owner: self)
        pboard.setData(data, forType: .string)
        
        return true
    }

    func dragRow(from pasteboard: NSPasteboard) -> Int {
        let rowData = pasteboard.data(forType: NSPasteboard.PasteboardType.string)!
        let rowIndexes = NSKeyedUnarchiver.unarchiveObject(with: rowData) as! IndexSet
        return rowIndexes.first!
    }
    
    /// End drag-n-drop session without drop
    ///  used for delete
    ///
    func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        if operation == .delete || currentItemDragOperation == .delete {
            let fromRow = dragRow(from: session.draggingPasteboard)
            switch tableView {
            case favoriteTableView:
                dataStore.selectedBarSensors.remove(at: fromRow-1)
                NSAnimationEffect.poof.show(centeredAt: screenPoint, size: NSZeroSize)
                NotificationCenter.default.post(name: .barSensorsChangedNotification, object: nil)
                favoriteTableView.reloadData()
            case sensorsTableView:
                let device = devicesSensorsList[fromRow] as! SensorsOnDevice
                remove(device: device)
                NSAnimationEffect.poof.show(centeredAt: screenPoint, size: NSZeroSize)
            default: fatalError()
            }
        }
    }
    
    /// Determine valid drop target
    ///
    /// - Returns: operation
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        currentItemDragOperation = []
        let toRow = row
        let draggingSource = info.draggingSource() as! SelectTableView
        
        if tableView == favoriteTableView {
            let fromRow = dragRow(from: info.draggingPasteboard())
            
            if draggingSource == favoriteTableView {
                tableView.setDropRow(toRow, dropOperation: .above)
                currentItemDragOperation = toRow < 1 || toRow == fromRow || toRow == fromRow + 1 ? [] : .move
            }
            else if draggingSource == sensorsTableView {
                switch devicesSensorsList[fromRow] {
                case is SensorsOnDevice:
                    currentItemDragOperation = []
                case is Sensor:
                    tableView.setDropRow(toRow, dropOperation: .above)
                    currentItemDragOperation = .copy
                default: fatalError()
                }
            }
        }
        return currentItemDragOperation
    }

    /// Accept drop
    ///
    /// - Returns: true if drop accepted
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard tableView == sensorsTableView || tableView == favoriteTableView else { return false }
        let fromRow = dragRow(from: info.draggingPasteboard())

        switch info.draggingSource() as? NSTableView {
        case favoriteTableView?:
            let value = dataStore.selectedBarSensors[fromRow-1]
            dataStore.selectedBarSensors.remove(at: fromRow-1)
            if (row-1) > dataStore.selectedBarSensors.count {
                dataStore.selectedBarSensors.insert(value, at: row-2)
            }
            else {
                dataStore.selectedBarSensors.insert(value, at: row-1)
            }
            NotificationCenter.default.post(name: .barSensorsChangedNotification, object: nil)
            favoriteTableView.reloadData()
            return true
            
        case sensorsTableView?:
            guard let fromSensor = devicesSensorsList[fromRow] as? Sensor else { return false }
                dataStore.selectedBarSensors.append(fromSensor.id)
                NotificationCenter.default.post(name: .barSensorsChangedNotification, object: nil)
                favoriteTableView.reloadData()
                return true
        default:
            return false
        }
        
    }
    
}
