//
//  SelectTableView.swift
//  TestTabView
//
//  Created by Dmitriy Borovikov on 13.12.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class SelectTableView: NSTableView {

    var trackingArea: NSTrackingArea?
    
    override func draggingSession(_ session: NSDraggingSession, willBeginAt screenPoint: NSPoint) {
        super.draggingSession(session, willBeginAt: screenPoint)
        NSCursor.closedHand.set()
    }
    
    override func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        super.draggingSession(session, endedAt: screenPoint, operation: operation)
        NSCursor.openHand.set()
    }
    
    override func draggingSession(_ session: NSDraggingSession, movedTo screenPoint: NSPoint) {
        guard let viewController = delegate as? SensorSettingsViewController else { return }

        let windowPoint = window!.mouseLocationOutsideOfEventStream
        let localPoint = convert(windowPoint , from: nil)
        if viewController.currentItemDragOperation != .delete && viewController.hasDraggedFavoriteItem && isMousePoint(localPoint, in: NSInsetRect(visibleRect, -35, -35)) == false {
            viewController.currentItemDragOperation = .delete
        }
        else if viewController.currentItemDragOperation == .delete && viewController.hasDraggedFavoriteItem && isMousePoint(localPoint, in: NSInsetRect(visibleRect, -35, -35)) == true {
            viewController.currentItemDragOperation = []
        }
        
        switch viewController.currentItemDragOperation {
        case .delete:
            NSCursor.disappearingItem.set()
            session.animatesToStartingPositionsOnCancelOrFail = false
        case .private:
            NSCursor.operationNotAllowed.set()
            session.animatesToStartingPositionsOnCancelOrFail = true
        case .copy:
            NSCursor.dragCopy.set()
            session.animatesToStartingPositionsOnCancelOrFail = false
        default:
            NSCursor.closedHand.set()
            session.animatesToStartingPositionsOnCancelOrFail = true
        }
    }
}
