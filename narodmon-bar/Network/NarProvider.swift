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

typealias WuSuccessCompletion = (Data) -> Void
typealias WUFailureCompletion = (Error) -> Void

class NarProvider {
    static var shared: NarProvider = NarProvider()
    
    static func endpointClosure(_ target: NarodAPI) -> Endpoint<NarodAPI> {
        let endpoint = Endpoint<NarodAPI>(url: url(target),
                                           sampleResponseClosure: { return target.stubbedNetworkResponse },
                                           method: target.method,
                                           task: target.task,
                                           httpHeaderFields: target.headers)
        return endpoint
    }
    
    fileprivate static let instance = MoyaProvider<NarodAPI>(endpointClosure: NarProvider.endpointClosure
//                                                                   ,plugins: [NetworkLoggerPlugin(verbose: true)]
                                                                  )

    // MARK: - Public
    func request(_ target: NarodAPI) -> Promise<Void> {
        let (promise, resolve, reject) = Promise<Void>.pending()
        APIRequest(target,
                   success: { _ in
                    resolve(()) },
                   failure: reject)
        return promise
    }

    
    func request<T: Decodable>(_ target: NarodAPI) -> Promise<T> {
        let (promise, resolve, reject) = Promise<T>.pending()
        assert(target.mappingType == T.self)
        APIRequest(target,
                   success: { rawData in
                    self.parseData(data: rawData, resolve: resolve, reject: reject) },
                   failure: reject)
        return promise
    }
    
    
    func APIRequest(_ target: NarodAPI,
                    success: @escaping WuSuccessCompletion,
                    failure: @escaping WUFailureCompletion) {
        NarProvider.instance.request(target) { (result) in
                self.handleRequest(target: target, result: result, success: success, failure: failure) 
            }
    }

}


// MARK: wunderRequest implementation
extension NarProvider {
    
    // MARK: - Private
    
    fileprivate func handleRequest(target: NarodAPI, result: MoyaResult,
                                   success: @escaping WuSuccessCompletion,
                                   failure: @escaping WUFailureCompletion) {
        switch result {
        case let .success(moyaResponse):
            let data = moyaResponse.data
            let statusCode = moyaResponse.statusCode

            switch statusCode {
            case 200:
                if let APIError = checkResponce(data: data) {
                    failure(APIError)
                } else {
                    success(data)
                }
            default:
                let APIError = NarodNetworkError.serverError(message: "Responce status code: \(statusCode)")
                failure(APIError)
            }
            
        case let .failure(error):
            // Really network unreachable
            handleNetworkFailure(target, error: error, success: success, failure: failure)
        }
    }

    /// Check for fatal errors.
    /// On falal eroror, display error message end exit
    /// On non-fatal, return error
    ///
    private func checkFatal(error: NarodNetworkError, failure: @escaping WUFailureCompletion) {
        switch error {
        case .requestSyntaxError(let message),
             .notFound(let message),
             .apiKeyBlocked(let message),
             .responceSyntaxError(let message):
            fatalError(message)
        default:
            failure(error)
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
    fileprivate func parseData<T: Decodable>(data: Any, resolve: (T) -> Void, reject: (Error) -> Void) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        do {
            let jsonAble = try decoder.decode(T.self, from: data as! Data)
            resolve(jsonAble)
        } catch {
            print(error)
            let message = error.localizedDescription
            reject(NarodNetworkError.responceSyntaxError(message: message))
        }
    }
    
   
    /// just retry request
    fileprivate func handleNetworkFailure(_ target: NarodAPI, error: Swift.Error,
                                          success: @escaping WuSuccessCompletion,
                                          failure: @escaping WUFailureCompletion) {
        if target.requestRetry {
            delay(1) {
                print("Retry request")
                self.APIRequest(target, success: success, failure: failure)
            }
        } else {
            let message = error.localizedDescription
            failure(NarodNetworkError.networkFailure(message: message))
        }
    }
    
}
