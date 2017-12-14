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
        //[super draggingSession:session movedToPoint:screenPoint];
        guard let viewController = delegate as? SensorSettingsViewController else { return }

        let windowPoint: NSPoint? = window?.mouseLocationOutsideOfEventStream
        let localPoint = convert(windowPoint ?? NSPoint(), from: nil)
        if viewController.currentItemDragOperation != .delete && viewController.hasDraggedFavoriteItem && mouse(localPoint, in: NSInsetRect(visibleRect, -35, -35)) == false {
            viewController.currentItemDragOperation = .delete
        }
        else if viewController.currentItemDragOperation == .delete && viewController.hasDraggedFavoriteItem && mouse(localPoint, in: NSInsetRect(visibleRect, -35, -35)) == true {
            viewController.currentItemDragOperation = []
        }
        if viewController.currentItemDragOperation == .delete {
            NSCursor.disappearingItem.set()
            session.animatesToStartingPositionsOnCancelOrFail = false
        }
        else if viewController.currentItemDragOperation == .private {
            NSCursor.operationNotAllowed.set()
            session.animatesToStartingPositionsOnCancelOrFail = true
        }
        else if viewController.currentItemDragOperation == .copy {
            NSCursor.dragCopy.set()
            session.animatesToStartingPositionsOnCancelOrFail = false
        }
        else {
            NSCursor.closedHand.set()
            session.animatesToStartingPositionsOnCancelOrFail = true
        }
        
    }

}
