////
///  customFontMenu.swift
//
import Cocoa

class customFontMenu: NSMenu {

    let menuFont = NSFont.init(name: "Helvetica", size: 14)
    
    override init(title: String) {
        super.init(title: title)
        self.font = menuFont
    }
    
    required init(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.font = menuFont
    }
}
