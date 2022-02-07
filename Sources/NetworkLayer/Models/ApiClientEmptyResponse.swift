import Alamofire

public struct ApiClientEmptyResponse<ResponseError: Error & Decodable>: ApiClientResponse {
    public let data: ApiClientEmptyData?
    public let error: ResponseError?

    public init() {
        self.data = nil
        self.error = nil
    }
}

extension ApiClientEmptyResponse: Alamofire.EmptyResponse {
    static public func emptyValue() -> ApiClientEmptyResponse<ResponseError> {
        ApiClientEmptyResponse()
    }
}
