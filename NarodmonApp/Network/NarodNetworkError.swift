////
///  NarodNetworkError.swift
//

import Foundation
import Cocoa

/*
- 400 - ошибка синтаксиса в запросе к API;
- 401 - требуется авторизация;
- 403 - в доступе к объекту отказано;
- 404 - искомый объект не найден;
- 423 - ключ API заблокирован администратором;
- 429 - более 1 запроса в минуту;
- 434 - искомый объект отключен;
- 503 - сервер временно не обрабатывает запросы по техническим причинам.
*/

enum NarodNetworkError: Error {
    case requestSyntaxError(message: String)
    case authorizationNeed(message: String)
    case accessDenied(message: String)
    case notFound(message: String)
    case apiKeyBlocked(message: String)
    case frequentRequestError(message: String)
    case disconnectedError(message: String)
    case responceSyntaxError(message: String)
    case serverError(message: String)
    case networkFailure(message: String)
    
    func message() -> String {
        switch self {
        case .requestSyntaxError(let message),
             .authorizationNeed(let message),
             .accessDenied(let message),
             .notFound(let message),
             .apiKeyBlocked(let message),
             .frequentRequestError(let message),
             .disconnectedError(let message),
             .responceSyntaxError(let message),
             .networkFailure(let message),
             .serverError(let message):
            return message
        }
    }
}

extension NarodNetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .requestSyntaxError:
            return NSLocalizedString("Request syntax error", comment: "")
        case .authorizationNeed:
            return NSLocalizedString("Unsucessful authorisation", comment: "")
        case .accessDenied:
            return NSLocalizedString("Access denied", comment: "")
        case .notFound:
            return NSLocalizedString("Resource not found", comment: "")
        case .apiKeyBlocked:
            return NSLocalizedString("API key blocked", comment: "")
        case .frequentRequestError:
            return NSLocalizedString("Too frequent requests", comment: "")
        case .disconnectedError:
            return NSLocalizedString("Object disconnected", comment: "")
        case .responceSyntaxError:
            return NSLocalizedString("Responce syntax error", comment: "")
        case .serverError:
            return NSLocalizedString("Server error", comment: "")
        case .networkFailure:
            return NSLocalizedString("Network unreachable", comment: "")
        }
    }

}

extension NarodNetworkError {

    func displayAlert() {
        let alert = NSAlert()
        alert.messageText = self.localizedDescription
        alert.informativeText = self.message()
        alert.runModal()
    }
}
