//
//  SensorSettingsViewController.swift
//  TestTabView
//
//  Created by Dmitriy Borovikov on 11.12.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class SensorSettingsViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    var hasDraggedFavoriteItem = false
    var currentItemDragOperation: NSDragOperation = []
    
    @IBOutlet weak var sensorsTableView: SelectTableView!
    @IBOutlet weak var favoriteTableView: SelectTableView!
    
    var targetDataArray: [Int] = []

    var devicesSensorsList: [Any] = []
    lazy var dataStore = (NSApp.delegate as! AppDelegate).dataStore
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sensorsTableView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
        sensorsTableView.setDraggingSourceOperationMask(.move, forLocal: true)
        favoriteTableView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
        favoriteTableView.setDraggingSourceOperationMask([.move, .delete], forLocal: true)
    
        devicesSensorsList = dataStore.selectionsList()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        switch tableView {
        case sensorsTableView:
            return devicesSensorsList.count
        case favoriteTableView:
            return targetDataArray.count + 1
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
                sensorCell.setContent(sensor: sensor)
                return sensorCell
            default: fatalError()
            }

            
        case favoriteTableView:
            if row == 0 {
                return tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self)
            } else {
                let listRow = targetDataArray[row-1]
                guard let sensor = devicesSensorsList[listRow] as? Sensor else { return nil }
                guard let sensorCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SensorCell"), owner: self) as? PrefsCellView
                    else { return nil }
                sensorCell.setContent(sensor: sensor)
                return sensorCell
            }
            
        default: fatalError()
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
    
    /// Start drag-n-drop
    ///
    /// - Returns: true if drag is allowed
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        guard tableView == sensorsTableView || tableView == favoriteTableView else { return false }
        let row = rowIndexes.first!
        switch tableView {
        case sensorsTableView:
            hasDraggedFavoriteItem = false
            if devicesSensorsList[row] is SensorsOnDevice {
                return false
            }
            if targetDataArray.contains(row) {
                return false
            }
        case favoriteTableView:
            if row == 0 {
                return false
            }
            hasDraggedFavoriteItem = true
        default:
            return false
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
        if tableView == favoriteTableView && (operation == .delete || currentItemDragOperation == .delete) {
            let row = dragRow(from: session.draggingPasteboard)
            targetDataArray.remove(at: row-1)
            NSAnimationEffect.poof.show(centeredAt: screenPoint, size: NSZeroSize)
            favoriteTableView.reloadData()
        }
    }
    
//    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
//        if dropOperation == .above {
//            return .move
//        }
//        return .every
//    }

    /// Determine valid drop target
    ///
    /// - Returns: operation
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        currentItemDragOperation = []
        let toRow = row
        let draggingSource = info.draggingSource() as! SelectTableView
        
        if tableView == favoriteTableView {
            tableView.setDropRow(toRow, dropOperation: .above)
            let fromRow = dragRow(from: info.draggingPasteboard())
            
            if draggingSource == favoriteTableView {
                currentItemDragOperation = toRow < 1 || toRow == fromRow || toRow == fromRow + 1 ? [] : .move
            }
            else if draggingSource == sensorsTableView {
                currentItemDragOperation = .copy
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
            let value = targetDataArray[fromRow-1]
            targetDataArray.remove(at: fromRow-1)
            if (row-1) > targetDataArray.count {
                targetDataArray.insert(value, at: row-2)
            }
            else {
                targetDataArray.insert(value, at: row-1)
            }
            favoriteTableView.reloadData()
            return true
            
        case sensorsTableView?:
            targetDataArray.append(fromRow)
            favoriteTableView.reloadData()
            return true
            
        default:
            return false
        }
        
    }
    
}
