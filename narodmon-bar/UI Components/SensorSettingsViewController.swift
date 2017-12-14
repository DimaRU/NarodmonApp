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
    
    var sourceDataArray: [String] = ["One","Two","Three","Four"]
    var targetDataArray: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sensorsTableView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
        sensorsTableView.setDraggingSourceOperationMask(.move, forLocal: true)
        favoriteTableView.registerForDraggedTypes([NSPasteboard.PasteboardType.string])
        favoriteTableView.setDraggingSourceOperationMask([.move, .delete], forLocal: true)

    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        switch tableView {
        case sensorsTableView:
            return sourceDataArray.count
        case favoriteTableView:
            return targetDataArray.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let view = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: self) as? NSTableCellView else { return nil }
        switch tableView {
        case sensorsTableView:
            view.textField?.stringValue = sourceDataArray[row]
        case favoriteTableView:
            view.textField?.stringValue = targetDataArray[row]
        default:
            return nil
        }
        return view
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return false
    }
    
    func tableView(_ tableView: NSTableView, writeRowsWith rowIndexes: IndexSet, to pboard: NSPasteboard) -> Bool {
        guard tableView == sensorsTableView || tableView == favoriteTableView else { return false }
        if tableView == sensorsTableView {
            let value = sourceDataArray[rowIndexes.first!]
            if targetDataArray.contains(value) {
                return false
            }
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
            targetDataArray.remove(at: rowIndexes.first!)
            NSAnimationEffect.poof.show(centeredAt: screenPoint, size: NSZeroSize)
        }
    }
    
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if dropOperation == .above {
            return .move
        }
        return .every
    }
    
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard tableView == sensorsTableView || tableView == favoriteTableView else { return false }
        let data = info.draggingPasteboard().data(forType: .string)!
        let rowIndexes = NSKeyedUnarchiver.unarchiveObject(with: data) as! IndexSet

        if tableView == sensorsTableView {
            targetDataArray.remove(at: rowIndexes.first!)
            favoriteTableView.reloadData()
            return true
        }

        switch info.draggingSource() as? NSTableView {
        case favoriteTableView?:
            let value = targetDataArray[rowIndexes.first!]
            targetDataArray.remove(at: rowIndexes.first!)
            if row > targetDataArray.count {
                targetDataArray.insert(value, at: row-1)
            }
            else {
                targetDataArray.insert(value, at: row)
            }
            favoriteTableView.reloadData()
            return true
            
        case sensorsTableView?:
            let value = sourceDataArray[rowIndexes.first!]
            targetDataArray.append(value)
            favoriteTableView.reloadData()
            return true
            
        default:
            return false
        }
        
    }
    
}
