////
///  String+MD5.swift
//

extension String {
    /**
     Get the MD5 hash of this String
     
     - returns: MD5 hash of this String
     */
    func md5() -> String! {
        return MD5Hashing.md5(str: self)
    }
}

