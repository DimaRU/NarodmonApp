////
///  StatusItemView.swift
//

import Cocoa

typealias Completion = () -> Void

final class StatusItemView: NSView {

	private let tappedCallback: Completion
    private var deviceListObserver: NotificationObserver?
    private var dataObserver: NotificationObserver?
    private var barSensorsObserver: NotificationObserver?
    
    var statusItem: NSStatusItem!

    private static let tinyText = [ NSAttributedStringKey.font: NSFont.systemFont(ofSize: 9, weight: .semibold),
                                      NSAttributedStringKey.foregroundColor: NSColor.controlTextColor ]
    private static let normalText = [ NSAttributedStringKey.font: NSFont.systemFont(ofSize: 14),
                                      NSAttributedStringKey.foregroundColor: NSColor.controlTextColor ]
    static private let padding: CGFloat = 4.0

    var dataStore: AppDataStore!
    var sensorLabels: [(String, NSColor?)] = []

    var isTinyText = true {
        didSet {
            sizeToFit()
        }
    }
    
	var highlighted = false {
		didSet {
			if highlighted != oldValue {
				needsDisplay = true
			}
		}
	}

    init(statusItem: NSStatusItem, dataStore: AppDataStore, callback: @escaping Completion) {
        self.statusItem = statusItem
		tappedCallback = callback
        self.dataStore = dataStore

        super.init(frame: NSZeroRect)
        self.statusItem.view = self

        deviceListObserver = NotificationObserver(forName: .deviceListChangedNotification) {
            self.dataRefreshed()
        }
        dataObserver = NotificationObserver(forName: .dataChangedNotification) {
            self.dataRefreshed()
        }
        barSensorsObserver = NotificationObserver(forName: .barSensorsChangedNotification) {
            self.dataRefreshed()
        }

        sensorLabels = [(NSLocalizedString("Loading...", comment: "Status bar message"), nil)]
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func mouseDown(with theEvent: NSEvent) {
		tappedCallback()
	}
    
    private func formatedSensorLabels() -> [(String, NSColor?)] {
        var labels: [(String, NSColor?)] = []

        for id in dataStore.selectedBarSensors {
            guard let (value, unit, color) = dataStore.sensorData(for: id) else { continue }
            let label = String.init(format: "%.0f", value) + unit
            labels.append((label, color))
        }
        return labels.isEmpty ? [
            (NSLocalizedString("No", comment: "Empty status bar message part1"), nil),
            (NSLocalizedString("sensors", comment: "Empty status bar message part2"), nil)
            ] : labels
    }
    
    func dataRefreshed() {
        let newSensorLabels = formatedSensorLabels()
//        if sensorLabels == newSensorLabels {
//            return
//        }
        sensorLabels = newSensorLabels
        sizeToFit()
    }
    
    /// Calc and set status bar item frame size
	public func sizeToFit() {
        let textAttributes = isTinyText ? StatusItemView.tinyText : StatusItemView.normalText

        var offset: CGFloat = StatusItemView.padding
        var prevWidth: CGFloat = 0
        for (i, (sensorLabel, _)) in sensorLabels.enumerated() {
            let width = round(sensorLabel.size(withAttributes: textAttributes).width)
            if isTinyText {
                if i % 2 == 0 {
                    prevWidth = width
                    if i == sensorLabels.count - 1 {
                        offset += width + StatusItemView.padding
                    }
                } else {
                    offset += (width > prevWidth ? width : prevWidth) + StatusItemView.padding
                }
            } else {
                offset += width + StatusItemView.padding
            }
        }

        setFrameSize(NSSize(width: offset, height: NSStatusBar.system.thickness))
        needsDisplay = true
	}

	override func draw(_ dirtyRect: NSRect) {

		statusItem.drawStatusBarBackground(in: dirtyRect, withHighlight: highlighted)

        let textAttributes = isTinyText ? StatusItemView.tinyText : StatusItemView.normalText
		var countAttributes = textAttributes

        var offset: CGFloat = StatusItemView.padding
        var prevWidth: CGFloat = 0
        var width: CGFloat
        for (i, (sensorLabel, color)) in sensorLabels.enumerated() {
            var drawPoint: NSPoint

            countAttributes[NSAttributedStringKey.foregroundColor] = color ?? (highlighted ? .selectedMenuItemTextColor : .controlTextColor)
            let attributed = NSMutableAttributedString(string: sensorLabel, attributes: countAttributes)

            width = round(sensorLabel.size(withAttributes: textAttributes).width)
            if isTinyText {
                if i % 2 == 0 {
                    prevWidth = width
                    if i == sensorLabels.count - 1 {
                        drawPoint = NSPoint(x: offset, y: round((frame.size.height - attributed.size().height) / 2))
                    } else {
                        drawPoint = NSPoint(x:offset, y: round(frame.size.height / 2) - 1)
                    }
                } else {
                    width = width > prevWidth ? width : prevWidth
                    drawPoint = NSPoint(x: offset, y: round(frame.size.height / 2) - attributed.size().height + 2)
                    offset += width + StatusItemView.padding
                }
            } else {
                drawPoint = NSPoint(x: offset, y: round((frame.size.height - attributed.size().height) / 2) + 1)
                offset += width + StatusItemView.padding
            }
            attributed.draw(at: drawPoint)
        }


	}

}
