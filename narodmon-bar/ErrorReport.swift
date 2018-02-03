//
//  ErrorReport.swift
//  NarodmonBar
//
//  Created by Dmitriy Borovikov on 29.01.2018.
//  Copyright © 2018 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import PromiseKit

extension Error {
    
    func sendFatalReport() -> Never {
        print(self)
        let errorDescription = self.localizedDescription
        let errorDetail: String
        
        if case let e as NarodNetworkError = self {
            errorDetail = e.message()
        } else {
            errorDetail = ""
        }
        
        _ = NarProvider.shared.request(.sendReport(message: errorDescription, logs: errorDetail))
        
        usleep(200000)      // 0.2 sec for send Req
        fatalError(errorDescription)
    }

}
