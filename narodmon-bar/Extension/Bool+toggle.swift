////
///  Bool+toggle.swift
//

extension Bool {
    @discardableResult
    mutating func toogle() -> Bool {
        self = !self
        return self
    }
}
