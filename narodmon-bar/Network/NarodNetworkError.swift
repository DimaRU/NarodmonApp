////
///  NarodNetworkError.swift
//

import Foundation

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
    case serverError
    case statusError(code: Int)
}

