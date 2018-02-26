//
//  PrefsCellView.swift
//  TestTabView
//
//  Created by Dmitriy Borovikov on 14.12.2017.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//

import Cocoa

class PrefsCellView: NSTableCellView, NSTextFieldDelegate {

    @IBOutlet weak var checkBox: NSButton?
    @IBOutlet weak var sensorNameLabel: NSTextField!
    @IBOutlet weak var sensorValueLabel: NSTextField?
    @IBOutlet weak var sensorMinTextField: NSTextField?
    @IBOutlet weak var sensorMaxTextField: NSTextField?
    private var sensorId: Int!
    weak var dataStore: AppDataStore!


    override func resetCursorRects() {
        discardCursorRects()
        if let checkBox = checkBox {
            addCursorRect(checkBox.frame, cursor: NSCursor.pointingHand)
        } else {
            addCursorRect(frame, cursor: NSCursor.openHand)
        }
    }
   
    func setContent(sensor: Sensor, dataStore: AppDataStore) {
        self.dataStore = dataStore
        sensorId = sensor.id
        sensorNameLabel.stringValue = sensor.name
        sensorValueLabel?.stringValue = "\(sensor.value)\(sensor.unit)"
        checkBox?.state = dataStore.selectedWindowSensors.contains(sensor.id) ? .on : .off
        sensorMinTextField?.delegate = self
        sensorMaxTextField?.delegate = self
        let formater = NumberFormatter()
        formater.numberStyle = .decimal

        if let min = dataStore.sensorsMin[sensorId] {
            sensorMinTextField?.stringValue = formater.string(from: NSNumber(value: min)) ?? ""
        }
        if let max = dataStore.sensorsMax[sensorId] {
            sensorMaxTextField?.stringValue = formater.string(from: NSNumber(value: max)) ?? ""
        }
    }
    
    @IBAction func checkBoxSensorAction(_ sender: NSButton) {
        if sender.state == .on {
            dataStore.selectedWindowSensors.append(sensorId)
        }
        else {
            let index = dataStore.selectedWindowSensors.index(where: {$0 == sensorId})!
            dataStore.selectedWindowSensors.remove(at: index)
        }
        postNotification(name: .popupSensorsChangedNotification)
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        guard let textField = obj.object as? NSTextField else { return }
        
        let formater = NumberFormatter()
        formater.numberStyle = .decimal
        let value = formater.number(from: textField.stringValue)?.doubleValue ?? nil
        
        switch textField {
        case sensorMinTextField!:
            dataStore.sensorsMin[sensorId] = value
        case sensorMaxTextField!:
            dataStore.sensorsMax[sensorId] = value
        default:
            print(textField)
            fatalError()
        }
    }
}
