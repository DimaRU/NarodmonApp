//
//  ChartViewController.swift
//  testCharts
//
//  Created by Dmitriy Borovikov on 04.03.2018.
//  Copyright © 2018 Dmitriy Borovikov. All rights reserved.
//

import Cocoa
import Charts

class ChartViewController: NSViewController {

    @IBOutlet weak var currentDataLabel: NSTextField!
    @IBOutlet weak var chartView: FixLineChartView!
    @IBOutlet weak var nextButton: NSButton!
    @IBOutlet weak var prevButton: NSButton!
    @IBOutlet weak var radioButtonsView: NSStackView!
    
    private let radioButtonTags: [Int:HistoryPeriod] = [1 : .hour, 2 : .day, 3: .week, 4: .month, 5: .year ]
    private let OnButtonState = NSControl.StateValue.on
    private let OffButtonState = NSControl.StateValue.off
    

    private var historyPeriod: HistoryPeriod = .day
    private var historyOffset: Int = 0
    private var history: [SensorHistoryData] = []
    var sensor: Sensor!
    var location: String!
    
    @IBAction func chartRangeSwitch(_ sender: NSButton) {
        let parentView = sender.cell?.controlView?.superview
        for button in parentView!.subviews where button is NSButton {
            let button = button as! NSButton
            if !button.isEnabled {
                button.isEnabled = true
                button.state = OffButtonState
            }
        }
        sender.isEnabled = false
        historyPeriod = radioButtonTags[sender.tag]!
        redrawChart()
    }
    
    @IBAction func prevButtonPress(_ sender: NSButton) {
        historyOffset += 1
        nextButton.isEnabled = true
        redrawChart()
    }
    
    @IBAction func nextButtonPress(_ sender: NSButton) {
        historyOffset -= 1
        if historyOffset <= 0 {
            historyOffset = 0
            nextButton.isEnabled = false
        }
        redrawChart()
    }

    public class func instance() -> ChartViewController {
        return NSStoryboard.main?.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "ChartViewController")) as! ChartViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // setup radioButtons
        for button in radioButtonsView.subviews where button is NSButton {
            let button = button as! NSButton
            if radioButtonTags[button.tag]! == historyPeriod {
                button.isEnabled = false
                button.state = OnButtonState
            } else {
                button.isEnabled = true
                button.state = OffButtonState
            }
        }
        
        currentDataLabel.stringValue = ""
        if historyOffset == 0 {
            nextButton.isEnabled = false
        }
        chartView.noDataText = NSLocalizedString("No history data for that period", comment: "Chart view")
    }
    
    func prepareDataSet(history: [SensorHistoryData], sensor: Sensor) -> LineChartDataSet {
        var min = history.first!.value
        var max = history.first!.value
        var sum: Double = 0.0
        
        var dataEntries: [ChartDataEntry] = []
        for (i, data) in history.enumerated() {
            let dataEntry = ChartDataEntry(x: data.time.timeIntervalSince1970, y: data.value, data: i as AnyObject)
            dataEntries.append(dataEntry)
            if data.value < min { min = data.value }
            if data.value > max { max = data.value }
            sum += data.value
        }
        let average = sum / Double(history.count)
        
        let (from, to) = smartRange(from: history.first!.time, to: history.last!.time)
        var args: [CVarArg] = []
        args.append(sensor.name)
        args.append(sensor.unit)
        args.append(from)
        args.append(to)
        args.append(min)
        args.append(max)
        args.append(average)

        //"Температура in C\tMin: 8.1\tMax: 9.5\tAvg: 9.1")
        let format = NSLocalizedString("%@ in %@\t%@ - %@\tMin: %0.1f\tMax: %0.1f\tAverage: %0.1f", comment: "Chart legend")

        let label = String.init(format: format, arguments: args)
        let dataSet = LineChartDataSet(values: dataEntries, label: label)

        return dataSet
    }
    
    func smartRange(from: Date, to: Date) -> (from: String, to: String) {
        let fromForm = DateFormatter()
        let toForm = DateFormatter()
        let cal = Calendar.current
        
        fromForm.timeStyle = .short
        toForm.timeStyle = .short
        
        let fromComp = cal.dateComponents([.day, .month, .year], from: from)
        let toComp = cal.dateComponents([.day, .month, .year], from: to)
        
        if cal.isDateInToday(from) {
            // Today
            fromForm.dateStyle = .none
            toForm.dateStyle = .none
        } else if fromComp == toComp {
            // Same day
            fromForm.dateStyle = .short
            toForm.dateStyle = .none
        } else {
            // Not same day
            fromForm.dateStyle = .short
            toForm.dateStyle = .short
        }
        
        if historyPeriod == .year {
            fromForm.dateStyle = .short
            toForm.dateStyle = .short

            fromForm.timeStyle = .none
            toForm.timeStyle = .none
        }
        return (from: fromForm.string(from: from), to: toForm.string(from: to))
    }

    func setupChart(sensor: Sensor) {
        let gridColor = NSUIColor.secondaryLabelColor
        let textColor = NSUIColor.controlTextColor
        let axisColor = NSUIColor.controlColor
        let textFont = NSFont.systemFont(ofSize: 10)
        
        let xAxis = chartView.xAxis
        xAxis.labelFont = textFont
        xAxis.drawGridLinesEnabled = true
        xAxis.axisLineColor = axisColor
        xAxis.gridLineWidth = 0.5
        xAxis.gridColor = gridColor
        xAxis.labelTextColor = textColor

        xAxis.valueFormatter = DateAxisValueFormatter(historyPeriod: historyPeriod)
        xAxis.labelPosition = .bottom
        xAxis.labelRotationAngle = -90
        switch historyPeriod {
        case .hour:     xAxis.granularity = 60.0
        case .day:      xAxis.granularity = 60.0
        case .week:     xAxis.granularity = 60*60
        case .month:    xAxis.granularity = 60*60
        case .year:     xAxis.granularity = 60*60*24
        }
        xAxis.spaceMax = 1
        xAxis.spaceMin = 1
        xAxis.axisMaxLabels = 20
        xAxis.setLabelCount(history.count, force: false)
        
        let leftAxis = chartView.leftAxis
        leftAxis.drawZeroLineEnabled = false
        leftAxis.drawAxisLineEnabled = false
        leftAxis.drawLimitLinesBehindDataEnabled = true
        leftAxis.gridColor = gridColor
        leftAxis.gridLineWidth = 0.5
        leftAxis.labelTextColor = textColor
        leftAxis.labelFont = textFont
        leftAxis.granularity = 0.1

        func initLimitLine(limit: Double, color: NSColor, labelPosition: ChartLimitLine.LabelPosition) -> ChartLimitLine {
            let limitLine = ChartLimitLine(limit: limit)
            limitLine.labelPosition = labelPosition
            limitLine.valueTextColor = color
            limitLine.lineColor = color
            limitLine.lineWidth = 1.0;
            limitLine.lineDashLengths = [8, 3]
            limitLine.valueFont = textFont
            switch labelPosition {
            case .leftBottom: limitLine.label = NSLocalizedString("Low limit", comment: "Chart view")
            case .leftTop:    limitLine.label = NSLocalizedString("High limit", comment: "Chart view")
            default: fatalError()
            }
            return limitLine
        }
        
        leftAxis.removeAllLimitLines()
        leftAxis.addLimitLine(initLimitLine(limit: 23.5, color: .systemBlue, labelPosition: .leftBottom))
        leftAxis.addLimitLine(initLimitLine(limit: 24.5, color: .systemRed, labelPosition: .leftTop))
        
        let yValueFormater = DefaultAxisValueFormatter()
        yValueFormater.formatter = NumberFormatter()
        yValueFormater.formatter?.maximumFractionDigits = 1
        yValueFormater.formatter?.positiveSuffix = sensor.unit
        yValueFormater.formatter?.negativeSuffix = sensor.unit
        leftAxis.valueFormatter = yValueFormater
        chartView.rightAxis.enabled = false

        let description = Description()
        description.font = textFont
        description.textColor = .systemYellow
        description.text = location
        chartView.chartDescription = description

        chartView.dragEnabled = true
        chartView.scaleXEnabled = true
        chartView.scaleYEnabled = false
        chartView.pinchZoomEnabled = false
        chartView.doubleTapToZoomEnabled = true
        
        chartView.legend.yOffset = 2
        chartView.legend.enabled = true
        chartView.legend.textColor = textColor
        chartView.setExtraOffsets(left: 0, top: 0, right: 0, bottom: 12)

        chartView.delegate = self

        let chartDataSet = prepareDataSet(history: history, sensor: sensor)
        
        chartDataSet.colors = [NSColor(red:0.32, green:0.77, blue:0.84, alpha:1.00)]
        chartDataSet.circleColors = chartDataSet.colors
        chartDataSet.lineWidth = 2.0
        chartDataSet.circleHoleRadius = 2
        chartDataSet.circleRadius = 3
        chartDataSet.circleHoleColor = nil
        chartDataSet.drawCircleHoleEnabled = true
        chartDataSet.drawCirclesEnabled = false
        
        chartDataSet.drawValuesEnabled = false
        
        chartDataSet.formLineWidth = 2.0
        chartDataSet.formSize = 10.0
        chartDataSet.setDrawHighlightIndicators(true)
        chartDataSet.highlightColor = NSUIColor.selectedControlColor
        chartDataSet.highlightEnabled = true
        
        chartView.data = LineChartData(dataSet: chartDataSet)
    }

    override func viewDidAppear() {
        redrawChart()
    }

    private func redrawChart() {
        currentDataLabel.stringValue = ""
        CacheService.loadSensorHistory(id: sensor.id, period: historyPeriod, offset: historyOffset)
            .then { history -> Void in
                self.history = history
                if history.isEmpty {
                    self.chartView.noDataText = NSLocalizedString("No history data for that period", comment: "Chart view")
                    self.chartView.data = nil
                } else {
                    self.setupChart(sensor: self.sensor)
                }
                self.chartView.animate(xAxisDuration: 1, easingOption: .linear)
            }.catch { error in
                self.chartView.data = nil
                if let error = error as? NarodNetworkError {
                    error.displayAlert()
                } else {
                    fatalError(error.localizedDescription)
                }
                
        }
    }
}

extension ChartViewController: ChartViewDelegate {
    func chartValueSelected(_ chartView: ChartViewBase, entry: ChartDataEntry, highlight: Highlight) {
        let chartView = chartView as! LineChartView
        let value = chartView.leftAxis.valueFormatter!.stringForValue(entry.y, axis: nil)
        let formater = DateFormatter()
        formater.locale = Locale.current
        formater.dateStyle = .medium
        switch historyPeriod {
        case .hour:
            formater.timeStyle = .medium
        case .day:
            formater.timeStyle = .short
        case .week:
            formater.timeStyle = .short
        case .month:
            formater.timeStyle = .short
        case .year:
            formater.timeStyle = .none
        }
        let date = formater.string(from: Date(timeIntervalSince1970: entry.x))
        currentDataLabel.stringValue = "\(date)   \(value)"
    }
    
    func chartValueNothingSelected(_ chartView: ChartViewBase) {
        currentDataLabel.stringValue = ""
    }
    
    func chartScaled(_ chartView: ChartViewBase, scaleX: CGFloat, scaleY: CGFloat) {
        
    }
    
    func chartTranslated(_ chartView: ChartViewBase, dX: CGFloat, dY: CGFloat) {
        
    }

}

extension ChartViewController: NSPopoverDelegate {
    func popoverShouldClose(_ popover: NSPopover) -> Bool {
        return true
    }
    
    func popoverShouldDetach(_ popover: NSPopover) -> Bool {
        return true
    }
    
    func popoverDidDetach(_ popover: NSPopover) {
    }
    
    func popoverWillShow(_ notification: Notification) {
    }
    
    func popoverDidShow(_ notification: Notification) {
    }
    
    func popoverWillClose(_ notification: Notification) {
    }
    
    func popoverDidClose(_ notification: Notification) {
    }
}
