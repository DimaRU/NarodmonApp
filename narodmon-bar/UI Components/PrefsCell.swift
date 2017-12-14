//
//  PrefsCell.swift
//  TestTabView
//
//  Created by Dmitriy Borovikov on 14.12.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class PrefsCell: NSTableCellView {

    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(frame, cursor: NSCursor.openHand)
//        if checkBox != nil {
//            addCursorRect(checkBox.frame, cursor: NSCursor.pointingHand)
//        }
    }
}
