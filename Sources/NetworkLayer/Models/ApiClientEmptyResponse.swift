import Alamofire

struct ApiClientEmptyResponse<ResponseError: Error & Decodable>: ApiClientResponse {
    let data: ApiClientEmptyData?
    let error: ResponseError?

    init() {
        self.data = nil
        self.error = nil
    }
}

extension ApiClientEmptyResponse: Alamofire.EmptyResponse {
    static func emptyValue() -> ApiClientEmptyResponse<ResponseError> {
        ApiClientEmptyResponse()
    }
}
