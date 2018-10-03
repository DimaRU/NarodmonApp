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

protocol IdDelegate {
    func add(id: Int)
}

class SensorSettingsViewController: NSViewController {

    weak var dataStore: AppDataStore!
    weak var mapViewController: NSViewController? = nil
    
    private var sourceTableData: [Any] = []
    private var deviceCellStyle = 0
    private let deviceCellId = ["DeviceCell1", "DeviceCell2", "DeviceCell3"]
    private var sensorCellStyle = 0
    private let sensorCellId = ["SensorCell1", "SensorCell2"]

    var hasDraggedFavoriteItem = false
    var currentItemDragOperation: NSDragOperation = []
    
    @IBOutlet weak var sourceTableView: SelectTableView!
    @IBOutlet weak var barSensorsTableView: SelectTableView!
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
        
        sourceTableView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
        sourceTableView.setDraggingSourceOperationMask([.move, .delete], forLocal: true)
        barSensorsTableView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
        barSensorsTableView.setDraggingSourceOperationMask([.move, .delete], forLocal: true)

        sourceTableView.doubleAction = #selector(cellDobleClicked)
        largeFontCheckBox.state = Defaults[.TinyFont] ? .off : .on
        prepareViewControllerData()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: .deviceListChangedNotification, object: nil)
    }
    
    private func prepareViewControllerData() {
        sourceTableData = []
        sourceTableData.append(NSLocalizedString("Devices & Sensors", comment: "Devices & Sensors & Webcams table header"))
        sourceTableData.append(contentsOf: dataStore.devicesSensorsList())

        guard !dataStore.webcams.isEmpty else { return }
        sourceTableData.append(NSLocalizedString("Webcams", comment: "Devices & Sensors & Webcams table header"))
        sourceTableData.append(contentsOf: dataStore.webcams)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .deviceListChangedNotification, object: nil)
    }
    
    override func viewWillDisappear() {
        dataStore.saveDefaults()
        mapViewController?.view.window?.performClose(nil)
    }
        
    @objc func refreshData() {
        prepareViewControllerData()
        sourceTableView.reloadData()
        barSensorsTableView.reloadData()
    }
    
    @objc private func cellDobleClicked(_ sender: Any) {
        switch sourceTableData[sourceTableView.clickedRow] {
        case is SensorsOnDevice:
            deviceCellStyle = deviceCellId.nextIndex(deviceCellStyle)
        case is Sensor:
            sensorCellStyle = sensorCellId.nextIndex(sensorCellStyle)
        default:
            return
        }
        sourceTableView.reloadData()
    }

}


extension  SensorSettingsViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        switch tableView {
        case sourceTableView:
            return sourceTableData.count
        case barSensorsTableView:
            return dataStore.selectedBarSensors.count + 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        switch tableView {
        case sourceTableView:
            switch sourceTableData[row] {
            case is SensorsOnDevice: return true
            case is WebcamImages: return false
            case is String: return true
            default: return false
            }
        case barSensorsTableView:
            return row == 0
        default: fatalError()
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch tableView {
            
        case sourceTableView:
            switch sourceTableData[row] {
            case let headerTitle as String:
                let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self) as? NSTableCellView
                cell?.textField?.stringValue = headerTitle
                return cell
            case let device as SensorsOnDevice:
                let cellId = deviceCellId[deviceCellStyle]
                let deviceCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), owner: self) as? DeviceCellView
                deviceCell?.setContent(device: device)
                return deviceCell
            case let sensor as Sensor:
                let cellId = sensorCellId[sensorCellStyle]
                let sensorCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: cellId), owner: self) as? PrefsCellView
                sensorCell?.setContent(sensor: sensor, dataStore: dataStore)
                return sensorCell
            case let webcam as WebcamImages:
                let webcamCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "WebcamCell"), owner: self) as? WebcamCellView
                webcamCell?.setContent(webcam: webcam)
                return webcamCell
            default: fatalError()
            }

            
        case barSensorsTableView:
            if row == 0 {
                return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self)
            } else {
                let id = dataStore.selectedBarSensors[row-1]
                for element in sourceTableData {
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
        case sourceTableView:
            hasDraggedFavoriteItem = false
            switch sourceTableData[row] {
            case is String:
                return false
            case is WebcamImages,
                 is SensorsOnDevice:
                hasDraggedFavoriteItem = true
                currentItemDragOperation = .delete
            case let sensor as Sensor:
                if dataStore.selectedBarSensors.contains(sensor.id) {
                    return false
                }

            default:
                fatalError()
            }

        case barSensorsTableView:
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
            case barSensorsTableView:
                dataStore.selectedBarSensors.remove(at: fromRow-1)
                NSAnimationEffect.poof.show(centeredAt: screenPoint, size: NSZeroSize)
                postNotification(name: .barSensorsChangedNotification)
                barSensorsTableView.reloadData()
                
            case sourceTableView:
                switch sourceTableData[fromRow] {
                case let device as SensorsOnDevice:
                    dataStore.remove(device: device)
                    postNotification(name: .deviceListChangedNotification)
                    NSAnimationEffect.poof.show(centeredAt: screenPoint, size: NSZeroSize)
                case let webcam as WebcamImages:
                    let id = webcam.id!
                    dataStore.selectedWebcams.removeAll(where: {$0 == id})
                    dataStore.webcams.removeAll(where: {$0.id == id})
                    postNotification(name: .deviceListChangedNotification)
                    NSAnimationEffect.poof.show(centeredAt: screenPoint, size: NSZeroSize)
                default:
                    break
                }
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
        
        if tableView == barSensorsTableView {
            let fromRow = dragRow(from: info.draggingPasteboard())
            
            if draggingSource == barSensorsTableView {
                tableView.setDropRow(toRow, dropOperation: .above)
                currentItemDragOperation = toRow < 1 || toRow == fromRow || toRow == fromRow + 1 ? [] : .move
            }
            else if draggingSource == sourceTableView {
                switch sourceTableData[fromRow] {
                case is SensorsOnDevice,
                     is WebcamImages,
                     is String:
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
        guard tableView == sourceTableView || tableView == barSensorsTableView else { return false }
        let fromRow = dragRow(from: info.draggingPasteboard())

        switch info.draggingSource() as? NSTableView {
        case barSensorsTableView?:
            let value = dataStore.selectedBarSensors[fromRow-1]
            dataStore.selectedBarSensors.remove(at: fromRow-1)
            if (row-1) > dataStore.selectedBarSensors.count {
                dataStore.selectedBarSensors.insert(value, at: row-2)
            }
            else {
                dataStore.selectedBarSensors.insert(value, at: row-1)
            }
            postNotification(name: .barSensorsChangedNotification)
            barSensorsTableView.reloadData()
            return true
            
        case sourceTableView?:
            guard let fromSensor = sourceTableData[fromRow] as? Sensor else { return false }
                dataStore.selectedBarSensors.append(fromSensor.id)
                postNotification(name: .barSensorsChangedNotification)
                barSensorsTableView.reloadData()
                return true
        default:
            return false
        }
        
    }
}

// Mark: IdDelegate

extension SensorSettingsViewController: IdDelegate {
    
    public func add(id: Int) {
        if id > 0 {
            self.add(device: id)
        } else {
            self.add(camera: -id)
        }
    }
    
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
    
    func add(camera id: Int) {
        parent?.view.window?.makeKeyAndOrderFront(nil)
        
        guard !dataStore.selectedWebcams.contains(id) else {
            let alert = NSAlert()
            alert.messageText = NSLocalizedString("Add camera", comment: "Add camera")
            alert.informativeText = NSLocalizedString("Camera already in list", comment: "Add camera")
            alert.runModal()
            return
        }

        NarProvider.shared.request(.webcamImages(id: id, limit: 1, latest: nil))
            .done { (webcamImages: WebcamImages) -> Void in
                self.dataStore.selectedWebcams.append(id)
                self.dataStore.webcams.append(webcamImages)
                postNotification(name: .deviceListChangedNotification)
            }
            .catch { error in
                guard let e = error as? NarodNetworkError else { error.sendFatalReport() }
                e.displayAlert()
        }
    }
}
