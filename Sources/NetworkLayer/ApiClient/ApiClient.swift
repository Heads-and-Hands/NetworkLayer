import Alamofire
import Combine
import Foundation

open class ApiClient {
    public typealias Result<T: ApiClientResponse> = AnyPublisher<T.ResponseData, ApiClientError<T>>

    private let requestBuilder: RequestBuilder
    private let session: Session
    private let decoder: JSONDecoder
    private let finishableIntercepter: ApiClientFinishableInterceptor?

    public init(
        requestBuilder: RequestBuilder,
        session: Session,
        decoder: JSONDecoder,
        finishableIntercepter: ApiClientFinishableInterceptor?
    ) {
        self.requestBuilder = requestBuilder
        self.session = session
        self.decoder = decoder
        self.finishableIntercepter = finishableIntercepter
    }

    public func performRequest<T: ApiClientResponse>(requestFactory: (RequestBuilder) -> URLRequestHolder?) -> ApiClient.Result<T> {
        guard let request = requestFactory(requestBuilder)?.urlRequest else {
            return Future { $0(.failure(.internal(error: .badRequest))) }.eraseToAnyPublisher()
        }

        let publisher = session.request(request, interceptor: session.interceptor)
            .validate(statusCode: 100 ..< 400)
            .publishDecodable(type: T.self, queue: .global(), decoder: decoder)

        return handle(publisher: publisher, request: request)
    }

    public func performUploadRequest<T: ApiClientResponse>(
        requestFactory: (RequestBuilder) -> (request: URLRequestHolder, uploadForm: MultipartFormData)?
    ) -> ApiClient.Result<T> {
        guard let requestData = requestFactory(requestBuilder),
              let request = requestData.request.urlRequest else {
            return Future { $0(.failure(.internal(error: .badRequest))) }.eraseToAnyPublisher()
        }

        let publisher = session
            .upload(multipartFormData: requestData.uploadForm, with: request, interceptor: session.interceptor)
            .validate(statusCode: 100 ..< 400)
            .publishDecodable(type: T.self, queue: .global(), decoder: decoder)

        return handle(publisher: publisher, request: request)
    }

    private func handle<T>(publisher: DataResponsePublisher<T>, request: URLRequest) -> ApiClient.Result<T> {
        publisher
            .tryMap { [weak self] response in
                switch response.result {
                case let .success(value):
                    guard let statusCode = response.response?.statusCode else {
                        throw ApiClientError<T>.internal(error: .responseNotFound)
                    }

                    if let data = value.data {
                        self?.finishableIntercepter?.finish(request, responseData: data, statusCode: statusCode)
                        return data
                    } else if let error = value.error {
                        self?.finishableIntercepter?.finish(request, responseData: error, statusCode: statusCode)
                        throw ApiClientError<T>.server(statusCode: statusCode, responseError: error)
                    }
                case let .failure(error):
                    if error.isResponseValidationError,
                       let data = response.data,
                       let decodedResponse = try? self?.decoder.decode(T.self, from: data),
                       let statusCode = response.response?.statusCode,
                       let errorData = decodedResponse.error {
                        throw ApiClientError<T>.server(statusCode: statusCode, responseError: errorData)
                    }
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
