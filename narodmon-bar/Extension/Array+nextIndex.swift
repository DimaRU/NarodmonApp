////
///  Array+nextIndex.swift
//

extension Array {
    func nextIndex(_ i: Int) -> Int {
        if 0..<self.count-1 ~= i {
            return i+1
        }
        return 0
    }
}
