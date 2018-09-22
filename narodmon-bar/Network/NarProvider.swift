//
//  NarodProvider.swift
//
//  Created by Dmitriy Borovikov on 03.08.17.
//  Copyright © 2017 Dmitriy Borovikov. All rights reserved.
//
import Moya
import Result
import Alamofire
import PromiseKit

class NarProvider {
    typealias ErrorBlock = (Error) -> Void
    typealias RequestFuture = (target: NarodAPI, resolve: (Any) -> Void, reject: ErrorBlock)
    
    static var shared: NarProvider = NarProvider()
    
    static func endpointClosure(_ target: NarodAPI) -> Endpoint {
        let endpoint = Endpoint(url: url(target),
                                           sampleResponseClosure: { return target.stubbedNetworkResponse },
                                           method: target.method,
                                           task: target.task,
                                           httpHeaderFields: target.headers)
        return endpoint
    }
    
    #if DEBUG
    fileprivate static let instance = { () -> MoyaProvider<NarodAPI> in
        if let value = ProcessInfo.processInfo.environment["MoyaLogger"] {
            return MoyaProvider<NarodAPI>(endpointClosure: NarProvider.endpointClosure, plugins: [NetworkLoggerPlugin(verbose: true)])
        } else {
            return MoyaProvider<NarodAPI>(endpointClosure: NarProvider.endpointClosure)
        }
    }()
    #else
    fileprivate static let instance = MoyaProvider<NarodAPI>(endpointClosure: NarProvider.endpointClosure)
    #endif

    // MARK: - Public
    func request(_ target: NarodAPI) -> Promise<Void> {
        let (promise, resolver) = Promise<Void>.pending()
        sendRequest((target,
                     resolve: { _ in resolver.fulfill(()) },
                     reject: resolver.reject))
        return promise
    }

    
    func request<T: Decodable>(_ target: NarodAPI) -> Promise<T> {
        let (promise, resolver) = Promise<T>.pending()
        assert(target.mappingType == T.self)
        sendRequest((target,
                     resolve: { rawData in self.parseData(data: rawData as! Data, resolver: resolver, target: target) },
                     reject: resolver.reject))
        return promise
    }
    
    
    private func sendRequest(_ request: RequestFuture) {
        #if DEBUG
        print("Request:", request.target)
        #endif
        NarProvider.instance.request(request.target) { (result) in
            self.handleRequest(request: request, result: result)
        }
    }
}


// MARK: wunderRequest implementation
extension NarProvider {
    
    // MARK: - Private
    
    fileprivate func handleRequest(request: RequestFuture, result: MoyaResult) {
        switch result {
        case let .success(moyaResponse):
            let data = moyaResponse.data
            let statusCode = moyaResponse.statusCode

            switch statusCode {
            case 200:
                if let APIError = checkResponce(data: data) {
                    checkFatal(error: APIError, request: request)
                } else {
                    request.resolve(data)
                }
            default:
                let APIError = NarodNetworkError.serverError(message: "Responce status code: \(statusCode)")
                checkFatal(error: APIError, request: request)
            }
            
        case let .failure(error):
            // Really network unreachable
            handleNetworkFailure(request: request, error: error)
        }
    }

    /// Check for fatal errors.
    /// On falal eroror, display error message end exit
    /// On non-fatal, return error
    ///
    private func checkFatal(error: NarodNetworkError, request: RequestFuture) {
        switch error {
        case .requestSyntaxError,
             .apiKeyBlocked,
             .responceSyntaxError:
            error.displayAlert()
            error.sendFatalReport()
        default:
            request.reject(error)
        }
    }
    
    
    /// Pre-parce reply data and return error, if any
    ///
    /// - Parameter data: responce data
    /// - Returns: NarodNetworkError
    private func checkResponce(data: Data) -> NarodNetworkError? {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            if let dict = jsonObject as? [String : Any], let errno = dict["errno"] as? Int {
                let message = (dict["error"] as? String) ?? "Unknown"
                switch(errno) {
//                     - 400 - ошибка синтаксиса в запросе к API;
                case 400: return NarodNetworkError.requestSyntaxError(message: message)
//                     - 401 - требуется авторизация;
                case 401: return NarodNetworkError.authorizationNeed(message: message)
//                     - 403 - в доступе к объекту отказано;
                case 403: return NarodNetworkError.accessDenied(message: message)
//                     - 404 - искомый объект не найден; (APP_NOT_FOUND)
                case 404: return NarodNetworkError.notFound(message: message)
//                     - 423 - ключ API заблокирован администратором;   - really fatal
                case 423: return NarodNetworkError.apiKeyBlocked(message: message)
//                     - 429 - более 1 запроса в минуту; - just retry
                case 429: return NarodNetworkError.frequentRequestError(message: message)
//                     - 434 - искомый объект отключен;
                case 434: return NarodNetworkError.disconnectedError(message: message)
//                     - 503 - сервер временно не обрабатывает запросы по техническим причинам.
                case 503: return NarodNetworkError.serverError(message: message)
                default: return NarodNetworkError.responceSyntaxError(message: "Responce code: \(errno) \(message)")
                }
            }
        } catch {
            print(error)
            let message = error.localizedDescription
            return NarodNetworkError.responceSyntaxError(message: message)
        }
        return nil
    }
    
    /// Parce response data
    fileprivate func parseData<T: Decodable>(data: Data, resolver: Resolver<T>, target: NarodAPI) {
        let decoder = JSONDecoder()
        // Fuckin backend develpers!
        decoder.dateDecodingStrategy = .custom({ (decoder) -> Date in
            let container = try decoder.singleValueContainer()
            if let seconds = try? container.decode(Double.self) {
                return Date.init(timeIntervalSince1970: seconds)
            }
            if let secondsStr = try? container.decode(String.self), let seconds = Double(secondsStr) {
                return Date.init(timeIntervalSince1970: seconds)
            } else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Can't decode date")
            }
        })

        do {
            if T.self == SensorHistory.self {
                // Fuckin backend develpers!
                // Bugfix empty reply is "[]"
                if data.count == 2, data[0] == UInt8(ascii: "["), data[1] == UInt8(ascii: "]") {
                    let sensorHistoryData: [SensorHistoryData] = []
                    let sensorHistory = SensorHistory(data: sensorHistoryData)
                    resolver.fulfill(sensorHistory as! T)
                    return
                }
            }
            let jsonable = try decoder.decode(T.self, from: data)
            if var webcamImages = jsonable as? WebcamImages, case .webcamImages(let id, _, _) = target {
                webcamImages.id = id
                print(webcamImages)
                resolver.fulfill(webcamImages as! T)
            } else {
                resolver.fulfill(jsonable)
            }
        } catch {
            let json = String.init(data: data, encoding: .utf8) ?? "??unknown??"
            print(error)
            print(json)
            let message = error.localizedDescription
            resolver.reject(NarodNetworkError.responceSyntaxError(message: message))
        }
    }
    
   
    /// just retry request
    fileprivate func handleNetworkFailure(request: RequestFuture, error: Error) {
        if request.target.requestRetry {
            delay(1) {
                print("Retry request")
                self.sendRequest(request)
            }
        } else {
            let message = error.localizedDescription
            request.reject(NarodNetworkError.networkFailure(message: message))
        }
    }
    
}
