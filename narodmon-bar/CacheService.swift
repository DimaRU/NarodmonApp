////
///  CacheService.swift
//

import Foundation
import Cache
import PromiseKit

class CacheService {
    
    private static var storage: Storage = initCache()
    private static var expireTimer: Timer!
    
    private static func initCache() -> Storage {
        let diskConfig = DiskConfig(
            name: "NarodmonHistoryDataCache",
            expiry: .date(Date().addingTimeInterval(15*60)),
            maxSize: 10000,
            directory: nil,
            protectionType: .none
        )
        let memoryConfig = MemoryConfig(
            expiry: .date(Date().addingTimeInterval(5*60)),
            countLimit: 50,
            totalCostLimit: 10
        )

        let storage: Storage
        do {
            storage = try Storage(diskConfig: diskConfig, memoryConfig: memoryConfig)
        } catch {
            print(error)
            fatalError()
        }
        
        expireTimer = Timer.scheduledTimer(withTimeInterval: 30*60, repeats: true) {_ in 
            CacheService.clean()
        }
        return storage
    }

    public static func clean() {
        try? storage.removeExpiredObjects()
    }
    
    static func cacheKey(id: Int, period: HistoryPeriod, offset: Int) -> String {
        return "\(id)-\(period)-\(offset)"
    }
    
    public static func loadSensorHistory(id: Int, period: HistoryPeriod, offset: Int) -> Promise<[SensorHistoryData]> {
        let key = CacheService.cacheKey(id: id, period: period, offset: offset)
        
        if let historyData = try? CacheService.storage.object(ofType: [SensorHistoryData].self, forKey: key) {
            print("cached \(key)")
            return Promise<[SensorHistoryData]>(value: historyData)
        } else {
            return NetService.loadSensorHistory(id: id, period: period, offset: offset)
                .then { historyData -> [SensorHistoryData] in
                    let interval: Double
                    switch period {
                    case .hour:  interval = 4
                    case .day:   interval = 15
                    case .week:  interval = 15
                    case .month: interval = 30
                    case .year:  interval = 60
                    }
                    print("cache \(key)")
                    try? CacheService.storage.setObject(historyData, forKey: key, expiry: .date(Date().addingTimeInterval(interval*60)))
                    return historyData
            }
        }
    }

}
