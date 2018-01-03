//
//  SensorSettingsViewController.swift
//  TestTabView
//
//  Created by Dmitriy Borovikov on 11.12.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults

class SensorSettingsViewController: NSViewController {

    lazy var dataStore = (NSApp.delegate as! AppDelegate).dataStore
    
    private var selectedDevices: [Int] = []
    private var selectedBarSensors: [Int] = []
    private var selectedWindowSensors: Set<Int> = []
    private var devicesSensorsList: [Any] = []

    var hasDraggedFavoriteItem = false
    var currentItemDragOperation: NSDragOperation = []
    
    @IBOutlet weak var sensorsTableView: SelectTableView!
    @IBOutlet weak var favoriteTableView: SelectTableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sensorsTableView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
        sensorsTableView.setDraggingSourceOperationMask([.move, .delete], forLocal: true)
        favoriteTableView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
        favoriteTableView.setDraggingSourceOperationMask([.move, .delete], forLocal: true)

        loadViewData()
    }
    
    func loadViewData() {
        devicesSensorsList = dataStore.devicesSensorsList()
        
        selectedDevices = dataStore.selectedDevices
        selectedBarSensors = dataStore.selectedBarSensors
        selectedWindowSensors = Set<Int>(dataStore.selectedWindowSensors)
    }
    
    override func viewWillDisappear() {
        saveSettings()
        dataStore.saveDefaults()
        (NSApp.delegate as! AppDelegate).displaySensorData()
    }
    
    func saveSettings() {
        dataStore.selectedDevices = selectedDevices
        dataStore.selectedBarSensors = selectedBarSensors
        dataStore.selectedWindowSensors = Array<Int>(selectedWindowSensors)
    }

    func remove(device: SensorsOnDevice) {
        let sensorIds = Set<Int>(device.sensors.map { $0.id })
        
        selectedWindowSensors = selectedWindowSensors.filter { !sensorIds.contains($0) }
        selectedBarSensors = selectedBarSensors.filter { !sensorIds.contains($0) }
        selectedDevices = selectedDevices.filter{ $0 != device.id }
        saveSettings()
        
        devicesSensorsList = dataStore.devicesSensorsList()

        sensorsTableView.reloadData()
        favoriteTableView.reloadData()
    }

}




extension  SensorSettingsViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        switch tableView {
        case sensorsTableView:
            return devicesSensorsList.count
        case favoriteTableView:
            return selectedBarSensors.count + 1
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
                sensorCell.setContent(sensor: sensor, isChecked: selectedWindowSensors.contains(sensor.id))
                return sensorCell
            default: fatalError()
            }

            
        case favoriteTableView:
            if row == 0 {
                return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self)
            } else {
                let id = selectedBarSensors[row-1]
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
            if let sensor = devicesSensorsList[row] as? Sensor, selectedBarSensors.contains(sensor.id) {
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
                selectedBarSensors.remove(at: fromRow-1)
                NSAnimationEffect.poof.show(centeredAt: screenPoint, size: NSZeroSize)
                favoriteTableView.reloadData()
            case sensorsTableView:
                let device = devicesSensorsList[fromRow] as! SensorsOnDevice
                remove(device: device)
                print("Removed:", device.id)
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
            let value = selectedBarSensors[fromRow-1]
            selectedBarSensors.remove(at: fromRow-1)
            if (row-1) > selectedBarSensors.count {
                selectedBarSensors.insert(value, at: row-2)
            }
            else {
                selectedBarSensors.insert(value, at: row-1)
            }
            favoriteTableView.reloadData()
            return true
            
        case sensorsTableView?:
            if let fromSensor = devicesSensorsList[fromRow] as? Sensor {
                selectedBarSensors.append(fromSensor.id)
                favoriteTableView.reloadData()
                return true
            }
            else {
                return false
            }
                default:
            return false
        }
        
    }
    
}
