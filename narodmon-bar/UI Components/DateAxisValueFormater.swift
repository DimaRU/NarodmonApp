////
///
//

import Foundation
import Cocoa
import Charts

open class DateAxisValueFormatter: NSObject, AxisValueFormatter
{
    private let formatter = DateFormatter()
    
    public init(historyPeriod: HistoryPeriod)
    {
        super.init()
        
        let dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMd", options: 0, locale: Locale.current)!
        let template: String
        
        switch historyPeriod {
        case .hour:
            template = "HH:mm"
        case .day:
            template = "HH:mm"
        case .week:
            template = dateFormat + ", HH:mm"
        case .month:
            template = dateFormat + ", HH:mm"
        case .year:
            template = dateFormat
        }
        formatter.dateFormat = template
    }
    
    open func stringForValue(_ value: Double,
                             axis: AxisBase?) -> String
    {
        let date = Date(timeIntervalSince1970: value)
        return formatter.string(from: date)
    }
}
