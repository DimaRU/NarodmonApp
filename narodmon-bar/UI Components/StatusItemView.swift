////
///  StatusItemView.swift
//

import Cocoa

typealias Completion = () -> Void

final class StatusItemView: NSView {

	private let tappedCallback: Completion
    var statusItem: NSStatusItem!

    private static let tinyText = [ NSAttributedStringKey.font: NSFont.systemFont(ofSize: 9, weight: .semibold),
                                      NSAttributedStringKey.foregroundColor: NSColor.controlTextColor ]
    private static let normalText = [ NSAttributedStringKey.font: NSFont.systemFont(ofSize: 14),
                                      NSAttributedStringKey.foregroundColor: NSColor.controlTextColor ]
    static private let padding: CGFloat = 3.0

    var dataStore: AppDataStore!
    var sensorLabels: [String] = []
    var darkMode = false

    var isTinyText = true {
        didSet {
            sizeToFit()
        }
    }
    
	var grayOut = false {
		didSet {
			if grayOut != oldValue {
				needsDisplay = true
			}
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
        
        let center = NotificationCenter.default
        center.addObserver(forName: .dataChangedNotification, object: nil, queue: nil) { _ in
            self.dataRefreshed()
        }
        center.addObserver(forName: .barSensorsChangedNotification, object: nil, queue: nil) { _ in
            self.dataRefreshed()
        }
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	override func mouseDown(with theEvent: NSEvent) {
		tappedCallback()
	}
    
    private func formatedSensorLabels() -> [String] {
        var labels: [String] = []

        for id in dataStore.selectedBarSensors {
            guard let (value, unit) = dataStore.sensorData(for: id) else { continue }
            let label = String.init(format: "%.0f", value) + unit
            labels.append(label)
        }
        return labels.isEmpty ? ["Loading..."] : labels
    }
    
    func dataRefreshed() {
        let newSensorLabels = formatedSensorLabels()
        if sensorLabels == newSensorLabels {
            return
        }
        sensorLabels = newSensorLabels
        sizeToFit()
    }
    
    /// Calc and set status bar item frame size
	private func sizeToFit() {
        let textAttributes = isTinyText ? StatusItemView.tinyText : StatusItemView.normalText

        var offset: CGFloat = 0
        var prevWidth: CGFloat = 0
        for (i, sensorLabel) in sensorLabels.enumerated() {
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
		var foreground: NSColor

		if highlighted {
			foreground = .selectedMenuItemTextColor
			countAttributes[NSAttributedStringKey.foregroundColor] = foreground
		} else if darkMode {
			foreground = .selectedMenuItemTextColor
			if countAttributes[NSAttributedStringKey.foregroundColor] as! NSColor == NSColor.controlTextColor {
				countAttributes[NSAttributedStringKey.foregroundColor] = foreground
			}
		} else {
			foreground = .controlTextColor
		}

		if grayOut {
			countAttributes[NSAttributedStringKey.foregroundColor] = NSColor.disabledControlTextColor
		}

        var offset: CGFloat = 0
        var prevWidth: CGFloat = 0
        var width: CGFloat
        for (i, sensorLabel) in sensorLabels.enumerated() {
            var drawPoint: NSPoint
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
                drawPoint = NSPoint(x: offset, y: round((frame.size.height - attributed.size().height) / 2))
                offset += width + StatusItemView.padding
            }
            attributed.draw(at: drawPoint)
        }


	}

}
