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
                                                                   ,plugins: [NetworkLoggerPlugin(verbose: true)]
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
                if let networkError = checkResponce(data: data) {
                    failure(networkError)
                } else {
                    success(data)
                }
            default:
                let networkError = NarodNetworkError.networkError(code: statusCode)
                failure(networkError)
            }
            
        case let .failure(error):
            // Really network unreachable
            handleNetworkFailure(target, error: error, success: success, failure: failure)
        }
    }

    
    fileprivate func checkResponce(data: Data) -> NarodNetworkError? {
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
                case 503: return NarodNetworkError.serverError
                    
                default: return NarodNetworkError.networkError(code: errno)
                }
            }
        } catch {
            print(error)
            let message = error.localizedDescription
            return NarodNetworkError.replySyntaxError(message: message)
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
            reject(error)
        }
    }
    
   
    /// just retry request
    fileprivate func handleNetworkFailure(_ target: NarodAPI, error: Swift.Error?,
                                          success: @escaping WuSuccessCompletion,
                                          failure: @escaping WUFailureCompletion) {
        delay(1) {
            print("Retry request")
            self.APIRequest(target, success: success, failure: failure)
        }
    }
    
}
