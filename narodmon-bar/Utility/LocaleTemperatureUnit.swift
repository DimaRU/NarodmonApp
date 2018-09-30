////
///  LocaleTemperatureUnit.swift
//


import Foundation

func localeTemperatureUnit() -> UnitTemperature {
    let formatter = MeasurementFormatter()
    let temp = Measurement(value: 0, unit: UnitTemperature.celsius)
    if formatter.string(from: temp).last == "F" {
        return UnitTemperature.fahrenheit
    } else {
        return UnitTemperature.celsius
    }
}

