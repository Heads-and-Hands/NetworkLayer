import Alamofire
import Foundation

open class RequestBuilder {
    private let configuration: RequestBuilderConfiguration
    private let urlEncoder: URLEncodedFormParameterEncoder
    private let jsonEncoder: JSONEncoder
    private let plugins: [RequestBuilderPlugin]

    private var host: String {
        configuration.serverHost
    }

    public init(
        configuration: RequestBuilderConfiguration,
        urlEncoder: URLEncodedFormParameterEncoder,
        jsonEncoder: JSONEncoder,
        plugins: [RequestBuilderPlugin]
    ) {
        self.configuration = configuration
        self.urlEncoder = urlEncoder
        self.jsonEncoder = jsonEncoder
        self.plugins = plugins
    }

    open func make(method: HTTPMethod, path: String) -> URLRequestHolder {
        var urlRequest = URL(string: host)
            .map { $0.appendingPathComponent(path) }
            .flatMap { URLRequest(url: $0) }

        urlRequest?.method = method

        let holder = RequestBuilder.Request(
            urlRequest: urlRequest,
            urlEncoder: urlEncoder,
            jsonEncoder: jsonEncoder,
            debugMode: configuration.debugMode
        )

        plugins.forEach {
            $0.prepare(requestHolder: holder)
        }

        return holder
    }
}

private extension RequestBuilder {
    class Request: URLRequestHolder {
        var urlRequest: URLRequest?

        private let urlEncoder: URLEncodedFormParameterEncoder
        private let jsonEncoder: JSONEncoder
        private let debugMode: Bool

        init(
            urlRequest: URLRequest?,
            urlEncoder: URLEncodedFormParameterEncoder,
            jsonEncoder: JSONEncoder,
            debugMode: Bool
        ) {
            self.urlRequest = urlRequest
            self.urlEncoder = urlEncoder
            self.jsonEncoder = jsonEncoder
            self.debugMode = debugMode
        }

        func add<T: Encodable>(urlParameters: T, customEncoder: URLEncodedFormParameterEncoder?) -> URLRequestHolder {
            urlRequest = urlRequest.flatMap {
                try? (customEncoder ?? urlEncoder).encode(urlParameters, into: $0)
            }
            return self
        }

        func set<T: Encodable>(body: T, customEncoder: JSONEncoder?) -> URLRequestHolder {
            urlRequest?.httpBody = try? (customEncoder ?? jsonEncoder).encode(body)
            return self
        }

        func add(header: String, value: String) -> URLRequestHolder {
            urlRequest?.addValue(value, forHTTPHeaderField: header)
            return self
        }

        func mock(config: ((URLRequest) -> RequestMock)?) -> URLRequestHolder {
            guard debugMode else {
                return self
            }

            guard let request = urlRequest, let config = config else {
                return self
            }

            urlRequest?.set(mock: config(request))
            return self
        }
    }
}
