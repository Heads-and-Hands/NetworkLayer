import Alamofire
import Combine
import Foundation

public class ApiClient {
    public typealias Result<T: ApiClientResponse> = AnyPublisher<T.ResponseData, ApiClientError<T>>

    private let requestBuilder: RequestBuilder
    private let session: Session
    private let decoder: JSONDecoder

    public init(
        requestBuilder: RequestBuilder,
        session: Session,
        decoder: JSONDecoder
    ) {
        self.requestBuilder = requestBuilder
        self.session = session
        self.decoder = decoder
    }

    public func performRequest<T: ApiClientResponse>(requestFactory: (RequestBuilder) -> URLRequestHolder?) -> ApiClient.Result<T> {
        guard let request = requestFactory(requestBuilder)?.urlRequest else {
            return Future { $0(.failure(.internal(error: .badRequest))) }.eraseToAnyPublisher()
        }

        return session.request(request)
            .publishDecodable(type: T.self, queue: .global(), decoder: decoder)
            .tryMap { response in
                switch response.result {
                case let .success(value):
                    if let data = value.data {
                        return data
                    } else if let error = value.error, let statusCode = response.response?.statusCode {
                        throw ApiClientError<T>.server(statusCode: statusCode, responseError: error)
                    }
                case let .failure(error):
                    throw ApiClientError<T>.network(error: error)
                }

                throw ApiClientError<T>.internal(error: .responseNotFound)
            }
            .mapError { error -> ApiClientError<T> in
                if let apiClientError = error as? ApiClientError<T> {
                    return apiClientError
                } else {
                    return ApiClientError<T>.network(error: error)
                }
            }
            .eraseToAnyPublisher()
    }
}
