//
//  SettingsTabViewController.swift
//  Popover
//
//  Created by Dmitriy Borovikov on 11.01.2018.
//  Copyright © 2018 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class SettingsTabViewController: NSTabViewController {

    var dataStore: AppDataStore!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        view.window?.styleMask = [.titled, .closable]
    }
    
    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        if let viewController = tabViewItem?.viewController as? SensorSettingsViewController {
            viewController.dataStore = dataStore
        }
        super.tabView(tabView, willSelect: tabViewItem)

    }
}
