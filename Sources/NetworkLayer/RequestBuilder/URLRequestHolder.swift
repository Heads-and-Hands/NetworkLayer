import Alamofire
import Foundation

public protocol URLRequestHolder: AnyObject {
    var urlRequest: URLRequest? { get }

    func add<T: Encodable>(urlParameters: T, customEncoder: URLEncodedFormParameterEncoder?) -> URLRequestHolder
    func set<T: Encodable>(body: T, customEncoder: JSONEncoder?) -> URLRequestHolder
    func add(header: String, value: String) -> URLRequestHolder
    func set(timeout: TimeInterval) -> URLRequestHolder

    func mock(config: ((URLRequest) -> RequestMock)?) -> URLRequestHolder
}

public extension URLRequestHolder {
    func add<T: Encodable>(urlParameters: T) -> URLRequestHolder {
        add(urlParameters: urlParameters, customEncoder: nil)
    }

    func set<T: Encodable>(body: T) -> URLRequestHolder {
        set(body: body, customEncoder: nil)
    }

    func mock() -> URLRequestHolder {
        mock {
            RequestMock.default($0.url?.path, 200, $0.httpMethod ?? "get")
        }
    }
}
