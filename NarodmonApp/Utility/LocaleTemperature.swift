////
///  LocaleTemperature.swift
//


import Foundation

struct LocaleTemperature {

    static let LocaleTemperatureUnit = localeTemperatureUnit()

    static func localeTemperatureUnit() -> UnitTemperature {
        let formatter = MeasurementFormatter()
        let temp = Measurement(value: 0, unit: UnitTemperature.celsius)
        if formatter.string(from: temp).last == "F" {
            return UnitTemperature.fahrenheit
        } else {
            return UnitTemperature.celsius
        }
    }

    static public func convert(from value: Double) -> Double{
        let t = Measurement(value: value, unit: UnitTemperature.celsius)
        return t.converted(to: LocaleTemperature.LocaleTemperatureUnit).value
    }
    
    static public var unit: String {
        return LocaleTemperatureUnit.symbol
    }
}
