//
//  SettingsTabViewController.swift
//  Popover
//
//  Created by Dmitriy Borovikov on 11.01.2018.
//  Copyright © 2018 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class SettingsTabViewController: NSTabViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        view.window?.styleMask = [.titled, .closable]
    }
}
