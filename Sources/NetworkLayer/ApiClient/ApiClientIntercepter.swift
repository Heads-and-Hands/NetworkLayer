//
//  File.swift
//  
//
//  Created by basalaev on 01.02.2021.
//

import Foundation
import Alamofire

public protocol ApiClientFinishableInterceptor {
    func finish<T>(_ request: URLRequest, responseData: T?, statusCode: Int)
}

public enum ApiClientRequestType {
    case `default`
    case refreshSession
    case newSession
    case logout
}

public enum ApiClientResponseDataType {
    case `default`
    case newUser
}

public protocol ApiClientAdaptProvider: AnyObject {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void)
}

public protocol ApiClientIntercepterDelegate: AnyObject {
    func validate(request: URLRequest) -> ApiClientRequestType
    func validate<T>(reponseData: T?) -> ApiClientResponseDataType

    func didExpiredToken()
}

private class RetrierContainer {
    let request: URLRequest
    let completion: (RetryResult) -> Void

    init(request: URLRequest, completion: @escaping (RetryResult) -> Void) {
        self.request = request
        self.completion = completion
    }
}

public class ApiClientExpiredTokenIntercepter: RequestInterceptor, ApiClientFinishableInterceptor {
    public static let shared = ApiClientExpiredTokenIntercepter()

    public weak var delegate: ApiClientIntercepterDelegate?

    public weak var adaptProvider: ApiClientAdaptProvider?

    private init() {}

    public func finish<T>(_ request: URLRequest, responseData: T?, statusCode: Int) {
        guard let delegate = delegate, statusCode != 401 else {
            return
        }

        // TODO: - Временный костыль. ApiClient вызывает finish до того как сработает sink у паблишера
        // выполняемого запроса. Как итог - запросы повторяются со старым токеном
        queue.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, !self.containers.isEmpty else {
                return
            }

            switch delegate.validate(request: request) {
            case .refreshSession:
                self.drainContainers(with: .retry)
            case .newSession:
                switch delegate.validate(reponseData: responseData) {
                case .default:
                    self.drainContainers(with: .retry)
                case .newUser:
                    self.drainContainers(with: .doNotRetry)
                }
            default:
                return
            }
        }
    }

    public func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard let adaptProvider = adaptProvider else {
            completion(.success(urlRequest))
            return
        }
        adaptProvider.adapt(urlRequest, for: session, completion: completion)
    }

    public func retry(_ request: Request, for _: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let urlRequest = request.request, request.state != .cancelled, let delegate = delegate else {
            completion(.doNotRetry)
            return
        }

        guard case .responseValidationFailed(.unacceptableStatusCode(401)) = (error as? AFError) else {
            completion(.doNotRetry)
            return
        }

        switch delegate.validate(request: urlRequest) {
        case .`default`:
            queue.async { [weak self] in
                self?.containers.append(RetrierContainer(request: urlRequest, completion: completion))
            }
        default:
            completion(.doNotRetry)
        }
    }

    // MARK: - Private

    private let queue = DispatchQueue(label: "expired-token-queue")

    private var containers: [RetrierContainer] = [] {
        didSet {
            if oldValue.isEmpty {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.didExpiredToken()
                }
            }
        }
    }

    private func drainContainers(with retryResult: RetryResult) {
        containers.forEach { $0.completion(retryResult) }
        containers.removeAll()
    }
}
