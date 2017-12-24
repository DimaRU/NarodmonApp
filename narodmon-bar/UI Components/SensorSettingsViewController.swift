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
                guard let sensorCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SensorCell"), owner: self) as? PrefsCell
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
                guard let sensorCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SensorCell"), owner: self) as? PrefsCell
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
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        guard tableView == sensorsTableView || tableView == favoriteTableView else { return false }
        switch tableView {
        case sensorsTableView:
            hasDraggedFavoriteItem = false
            if targetDataArray.contains(rowIndexes.first!) {
                return false
            }
        case favoriteTableView:
            hasDraggedFavoriteItem = true
        default:
            return false
        }

        let data = NSKeyedArchiver.archivedData(withRootObject: rowIndexes)

        pboard.declareTypes([NSPasteboard.PasteboardType.string], owner: self)
        pboard.setData(data, forType: .string)
        
        return true
    }

    func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        if tableView == favoriteTableView && (operation == .delete || currentItemDragOperation == .delete) {
            let pboard = session.draggingPasteboard
            let rowData = pboard.data(forType: NSPasteboard.PasteboardType.string)!
            let rowIndexes = NSKeyedUnarchiver.unarchiveObject(with: rowData) as! IndexSet
            targetDataArray.remove(at: rowIndexes.first!-1)
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

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        currentItemDragOperation = []
        let toRow = row
        let draggingSource = info.draggingSource() as! SelectTableView
        
        if tableView == favoriteTableView {
            tableView.setDropRow(toRow, dropOperation: .above)
            
            let data = info.draggingPasteboard().data(forType: .string)!
            let rowIndexes = NSKeyedUnarchiver.unarchiveObject(with: data) as! IndexSet
            let fromRow = rowIndexes.first!
            
            if draggingSource == favoriteTableView {
                currentItemDragOperation = toRow < 1 || toRow == fromRow || toRow == fromRow + 1 ? [] : .move
            }
            else if draggingSource == sensorsTableView {
                currentItemDragOperation = .copy
                //                currentItemDragOperation = toRow > 0 ? .copy : []
            }
        }
        return currentItemDragOperation
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard tableView == sensorsTableView || tableView == favoriteTableView else { return false }
        let data = info.draggingPasteboard().data(forType: .string)!
        let rowIndexes = NSKeyedUnarchiver.unarchiveObject(with: data) as! IndexSet

       switch info.draggingSource() as? NSTableView {
        case favoriteTableView?:
            let toRow = rowIndexes.first! - 1
            let value = targetDataArray[toRow]
            targetDataArray.remove(at: toRow)
            if row > targetDataArray.count {
                targetDataArray.insert(value, at: row-1)
            }
            else {
                targetDataArray.insert(value, at: row)
            }
            favoriteTableView.reloadData()
            return true
            
        case sensorsTableView?:
            targetDataArray.append(rowIndexes.first!)
            favoriteTableView.reloadData()
            return true
            
        default:
            return false
        }
        
    }
    
}
