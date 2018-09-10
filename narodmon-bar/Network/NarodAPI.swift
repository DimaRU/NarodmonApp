////
/// NarodAPI.swift
//
import Foundation
import Moya
import Result
import SwiftyUserDefaults

typealias MoyaResult = Result<Moya.Response, Moya.MoyaError>


// MARK: - Provider setup
/// URL constants
let API_DOMAIN = "https://narodmon.ru"

public enum HistoryPeriod: String {
    case hour
    case day
    case week
    case month
    case year
}
// MARK: - Provider support

public enum NarodAPI: TargetType {
    case appInit(version: String, platform: String, model: String, timeZone: Int)
    case userLogon(login: String, password: String)
    case userLogout
    case userFavorites(webcams: [Int])
    case sensorsOnDevice(id: Int)
    case sensorsValues(sensorIds: [Int])
    case sensorHistory(id: Int, period: HistoryPeriod, offset: Int)
    case sensorsNearby(my: Bool)
    case sendReport(message: String, logs: String)
    case webcamsNearby(lat: Double, lng: Double, limit: Int)
    case webcamImages(id: Int, since: Date?)
    
    var mappingType: Decodable.Type {
        switch self {
        case .appInit:
            return AppInitData.self
        case .userLogon:
            return UserLogon.self
        case .userLogout:
            return UserLogout.self
        case .userFavorites:
            return UserFavorites.self
        case .sensorsOnDevice:
            return SensorsOnDevice.self
        case .sensorsValues:
            return SensorsValues.self
        case .sensorHistory:
            return SensorHistory.self
        case .sensorsNearby:
            return SensorsNearby.self
        case .sendReport:
            return RequestResult.self
        case .webcamsNearby:
            return WebcamsNearby.self
        case .webcamImages:
            return WebcamImages.self
        }
    }
}

extension NarodAPI {
    
    public var method: Moya.Method {
        return .post
    }
    
    public var path: String {
        return "/api"
    }
    
    
    /// Network unreachable reaction
    /// ## true - retry request until network reachable
    /// ## false - return error to caller
    public var requestRetry: Bool {
        switch self {
        case .sensorsValues:
            return false
        default:
            return true
        }
    }
}

extension NarodAPI {
  
    public var baseURL: URL { return URL(string: API_DOMAIN)! }

    public var task: Task {
        var parameters: [String : Any]
        switch self {

        case .appInit(let version, let platform, let model, let timeZone):
            parameters = [
                "cmd" : "appInit",
                "version" : version,
                "platform" : platform,
                "model" : model,
                "utc" : timeZone
                ]
        case .userLogon(let login, let password):
            parameters = [
                "cmd" : "userLogon",
                "login" : login,
                "hash" : passwordHash(password)
                ]
        case .userLogout:
            parameters = [
                "cmd" : "userLogout"
            ]
        case .userFavorites(let webcams):
            parameters = [
                "cmd" : "userFavorites"
            ]
            if !webcams.isEmpty {
                parameters["webcams"] = webcams
            }
        case .sensorsOnDevice(let id):
            parameters = [
                "cmd" : "sensorsOnDevice",
                "id" : id
            ]
        case .sensorsValues(let sensorIds):
            parameters = [
                "cmd" : "sensorsValues",
                "sensors" : sensorIds
            ]
        case .sensorHistory(let id, let period, let offset):
            parameters = [
                "cmd" : "sensorsHistory",
                "id" : id,
                "period" : period.rawValue,
                "offset" : offset
            ]
        case .sensorsNearby(let my):
            parameters = [
                "cmd" : "sensorsNearby",
                "my" : my
            ]
        case .sendReport(let message, let logs):
            parameters = [
                "cmd" : "sendReport",
                "time" : Date().timeIntervalSince1970,
                "mess" : message,
                "logs" : logs
            ]
            
        case .webcamsNearby(let lat, let lng, let limit):
            parameters = [
                "cmd" : "webcamsNearby",
                "lat" : String(lat),
                "lng" : String(lng),
                "limit" : limit
            ]

        case .webcamImages(let id, let since):
            parameters = [
                "cmd" : "webcamImages",
                "id" : id
            ]
            if let since = since {
                parameters["since"] = since.timeIntervalSince1970
            }
        }
        
        parameters["api_key"] = APIKeys.shared.apiKey
        parameters["uuid"] = Defaults[.MachineUUID]!
        parameters["lang"] = NSLocale.current.languageCode!

        return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
    }
    
    public var sampleData: Data {
        switch self {
        default:
            return stubbedData("none")
        }
    }

    var stubbedNetworkResponse: EndpointSampleResponse {
        switch self {
        default:
            return .networkResponse(200, sampleData)
        }
    }

    static let clientInstanceId = UUID().uuidString
    static let clientDeviceId = UUID().uuidString

    public var headers: [String : String]? {
        
        let assigned: [String: String] = [
            "Accept": "application/json",
            "Content-Type": "application/json",
            "User-Agent": "NarodmonMacOS",
            "Accept-Encoding": "gzip, deflate"
            ]
        return assigned
    }
    
}


func passwordHash(_ password: String) -> String {
    let hashSting = Defaults[.MachineUUID]! + password.md5()
    return hashSting.md5()
}

// MARK: - Provider support
func stubbedData(_ filename: String) -> Data {
    let bundle = Bundle.main
    let path = bundle.path(forResource: filename, ofType: "json")
    return (try! Data(contentsOf: URL(fileURLWithPath: path!)))
}

private extension String {
    var URLEscapedString: String {
        return self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed)!
    }
}

func url(_ route: TargetType) -> String {
    return route.baseURL.appendingPathComponent(route.path).absoluteString
}
