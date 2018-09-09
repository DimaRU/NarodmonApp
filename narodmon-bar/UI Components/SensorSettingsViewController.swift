//
//  SensorSettingsViewController.swift
//  TestTabView
//
//  Created by Dmitriy Borovikov on 11.12.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import SwiftyUserDefaults
import PromiseKit

protocol DeviceIdDelegate {
    func add(device id: Int)
}

protocol CameraIdDelegate {
    func add(camera id: Int)
}

class SensorSettingsViewController: NSViewController {

    weak var dataStore: AppDataStore!
    weak var mapViewController: NSViewController? = nil
    
    private var devicesSensorsList: [Any] = []
    private var deviceCellStyle = 0
    private let deviceCellId = ["DeviceCell1", "DeviceCell2", "DeviceCell3"]
    private var sensorCellStyle = 0
    private let sensorCellId = ["SensorCell1", "SensorCell2"]

    var hasDraggedFavoriteItem = false
    var currentItemDragOperation: NSDragOperation = []
    
    @IBOutlet weak var sensorsTableView: SelectTableView!
    @IBOutlet weak var favoriteTableView: SelectTableView!
    @IBOutlet weak var largeFontCheckBox: NSButton!
 
    @IBAction func largeFontCheckBoxAction(_ sender: NSButton) {
        let tinyFont: Bool = sender.state == .off
        Defaults[.TinyFont] = tinyFont
        let app = NSApp.delegate as! AppDelegate
        app.statusView.isTinyText = tinyFont
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch segue.destinationController {
        case let viewController as DeviceIDViewCotroller:
            viewController.delegate = self
        case let viewController as MapViewController:
            viewController.delegate = self
            mapViewController = viewController
        default:
            break
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sensorsTableView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
        sensorsTableView.setDraggingSourceOperationMask([.move, .delete], forLocal: true)
        favoriteTableView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
        favoriteTableView.setDraggingSourceOperationMask([.move, .delete], forLocal: true)

        sensorsTableView.doubleAction = #selector(cellDobleClicked)
        largeFontCheckBox.state = Defaults[.TinyFont] ? .off : .on
        devicesSensorsList = dataStore.devicesSensorsList()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: .deviceListChangedNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .deviceListChangedNotification, object: nil)
    }
    
    override func viewWillDisappear() {
        dataStore.saveDefaults()
        mapViewController?.view.window?.performClose(nil)
    }
        
    @objc func refreshData() {
        devicesSensorsList = dataStore.devicesSensorsList()
        sensorsTableView.reloadData()
        favoriteTableView.reloadData()
    }
    
    @objc private func cellDobleClicked(_ sender: Any) {
        switch devicesSensorsList[sensorsTableView.clickedRow] {
        case is SensorsOnDevice:
            deviceCellStyle = deviceCellId.nextIndex(deviceCellStyle)
        case is Sensor:
            sensorCellStyle = sensorCellId.nextIndex(sensorCellStyle)
        default: fatalError()
        }
        sensorsTableView.reloadData()
    }

}

extension SensorSettingsViewController: DeviceIdDelegate {
    func add(device id: Int) {
        parent?.view.window?.makeKeyAndOrderFront(nil)
        
        guard !dataStore.selectedDevices.contains(id) else {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Add device", comment: "Add device")
            alert.informativeText = NSLocalizedString("Device already added", comment: "Add device")
            alert.runModal()
            return
        }
        
        NarProvider.shared.request(.sensorsOnDevice(id: id))
            .done { (device: SensorsOnDevice) -> Void in
                self.dataStore.add(device: device)
                postNotification(name: .deviceListChangedNotification)
            }
            .catch { error in
                guard let e = error as? NarodNetworkError else { error.sendFatalReport() }
                e.displayAlert()
        }
    }
}

extension SensorSettingsViewController: CameraIdDelegate {
    func add(camera id: Int) {
        parent?.view.window?.makeKeyAndOrderFront(nil)
        
        NarProvider.shared.request(.userFavorites(webcams: []))
            .map { (userFavorites: UserFavorites) -> [Int] in
                userFavorites.webcams.map { $0.id }
            }.then { (webcamIds: [Int]) -> Promise<UserFavorites> in
                guard !webcamIds.contains(id) else {
                    return Promise(error: PMKError.cancelled)
                }
                let webcamsIdsUpdated = webcamIds + [id]
                return NarProvider.shared.request(.userFavorites(webcams: webcamsIdsUpdated))
            }.done { (userFavorites: UserFavorites) -> Void in
                userFavorites.webcams.forEach { print($0.id, $0.name) }
            }.catch(policy: .allErrors) { error in
                switch error {
                case PMKError.cancelled:
                    let alert = NSAlert()
                    alert.messageText = NSLocalizedString("Add camera", comment: "Add camera")
                    alert.informativeText = NSLocalizedString("Camera already in list", comment: "Add camera")
                    alert.runModal()
                case let e as NarodNetworkError:
                    e.displayAlert()
                default:
                    error.sendFatalReport()
                }
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
                let cellId = deviceCellId[deviceCellStyle]
                guard let deviceCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), owner: self) as? DeviceCellView
                    else { return nil }
                deviceCell.setContent(device: device)
                return deviceCell
            case let sensor as Sensor:
                let cellId = sensorCellId[sensorCellStyle]
                guard let sensorCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), owner: self) as? PrefsCellView
                    else { return nil }
                sensorCell.setContent(sensor: sensor, dataStore: dataStore)
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
                        sensorCell.setContent(sensor: sensor, dataStore: dataStore)
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
                postNotification(name: .barSensorsChangedNotification)
                favoriteTableView.reloadData()
            case sensorsTableView:
                guard let device = devicesSensorsList[fromRow] as? SensorsOnDevice else { break }
                dataStore.remove(device: device)
                postNotification(name: .deviceListChangedNotification)
                NSAnimationEffect.poof.show(centeredAt: screenPoint, size: NSZeroSize)
            default: fatalError()
            }
        }
    }
    
    /// Determine valid drop target
    ///
    /// - Returns: operation
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard let draggingSource = info.draggingSource() as? SelectTableView else {
            return []
        }
        currentItemDragOperation = []
        let toRow = row
        
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
            postNotification(name: .barSensorsChangedNotification)
            favoriteTableView.reloadData()
            return true
            
        case sensorsTableView?:
            guard let fromSensor = devicesSensorsList[fromRow] as? Sensor else { return false }
                dataStore.selectedBarSensors.append(fromSensor.id)
                postNotification(name: .barSensorsChangedNotification)
                favoriteTableView.reloadData()
                return true
        default:
            return false
        }
        
    }
    
}
