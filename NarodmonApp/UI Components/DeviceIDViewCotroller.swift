//
//  DeviceIDViewCotroller.swift
//  NarodmonApp
//
//  Created by Dmitriy Borovikov on 04.01.2018.
//  Copyright © 2018 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class DeviceIDViewCotroller: NSViewController {
    
    var delegate: IdDelegate? = nil

    @IBOutlet weak var deviceIDfield: NSTextField!
    
    @IBAction func okButtonPress(_ sender: NSButton) {
        if let id = Int(deviceIDfield.stringValue) {
            delegate?.add(id: id)
        }
        dismiss(sender)
    }
        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    
}
