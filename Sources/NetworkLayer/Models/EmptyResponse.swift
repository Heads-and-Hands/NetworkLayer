import Alamofire

struct EmptyResponse<ResponseError: Error & Decodable>: ApiClientResponse {
    let data: EmptyData?
    let error: ResponseError?

    init() {
        self.data = nil
        self.error = nil
    }
}

extension EmptyResponse: Alamofire.EmptyResponse {
    static func emptyValue() -> EmptyResponse<ResponseError> {
        EmptyResponse()
    }
}
