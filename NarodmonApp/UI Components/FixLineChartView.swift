////
///  FixLineChartView.swift
//

import Cocoa
import Charts

class FixLineChartView: LineChartView {
    
    override var mouseDownCanMoveWindow: Bool {
        get {
            return false
        }
    }
}
