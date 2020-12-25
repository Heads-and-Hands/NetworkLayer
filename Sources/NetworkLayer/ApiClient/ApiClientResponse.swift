import Foundation

public protocol ApiClientResponse: Decodable {
    associatedtype ResponseData: Decodable
    associatedtype ResponseError: Error & Decodable

    var data: ResponseData? { get }
    var error: ResponseError? { get }
}
