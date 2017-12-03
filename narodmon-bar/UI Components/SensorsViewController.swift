//
//  SensorsViewController.swift
//  narodmon-bar
//
//  Created by Dmitriy Borovikov on 28.11.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class SensorsViewController: NSViewController {

    @IBOutlet weak var toolbarView: NSView!
    @IBOutlet var settingsMenu: NSMenu!
    
    @IBAction func settingsButtonPressed(_ sender: NSButton) {
        let p = NSPoint(x: 0, y: sender.frame.height)
        settingsMenu.popUp(positioning: nil, at: p, in: sender)

    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbarView.layer?.backgroundColor = NSColor.headerColor.cgColor
        // Do view setup here.
    }
    
}
