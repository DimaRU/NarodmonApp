////
/// NarodAPI.swift
//
import Foundation
import Moya
import Result

typealias MoyaResult = Result<Moya.Response, Moya.MoyaError>


// MARK: - Provider setup
/// URL constants
let API_DOMAIN = "http://narodmon.ru"

public enum HistoryPeriod: String {
    case hour
    case day
    case week
    case mounth
    case year
}
// MARK: - Provider support

public enum NarodAPI: TargetType {
    case appInit(version: String, platform: String, model: String, timeZone: Int)
    case userLogon(login: String, password: String)
    case userLogout
    case userFavorites
    case sensorsOnDevice(id: Int)
    case sensorsValues(sensorIds: [Int])
    case sensorsHistory(id: Int, period: HistoryPeriod, offset: Int)
    case sensorsNearby(my: Bool)
    

    
    static let apiVersion = "/api"
    
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
        case .sensorsHistory:
            return SensorsHistory.self
        case .sensorsNearby:
            return SensorsNearby.self
        }
    }
}

extension NarodAPI {
    
    public var method: Moya.Method {
        return .post
    }
}

extension NarodAPI {
    
    public var path: String {
        return ""
    }
}

extension NarodAPI {
  
    public var baseURL: URL { return URL(string: API_DOMAIN + NarodAPI.apiVersion)! }

    public var task: Task {
        let parameters: [String : Any]
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
                "hash" : loginHash(login: login, password: password)
                ]
        case .userLogout:
            parameters = [
                "cmd" : "userLogout"
            ]
        case .userFavorites:
            parameters = [
                "cmd" : "userFavorites"
            ]
        case .sensorsOnDevice(let id):
            parameters = [
                "cmd" : "sensorsOnDevice",
                "id" : id
            ]
        case .sensorsValues(let sensorIds):
            parameters = [
                "cmd" : "sensorsValues",
                "sensors" : [sensorIds]
            ]
        case .sensorsHistory(let id, let period, let offset):
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
        }
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
            "api_key" : APIKeys.shared.apiKey,
            "uuid" : "uuid",
            "lang" : "ru"
            ]


        return assigned
    }
    
}


func loginHash(login: String, password: String) -> String {
    return "dummy"
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


