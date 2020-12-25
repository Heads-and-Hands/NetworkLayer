import Foundation

public enum ApiClientError<Response: ApiClientResponse>: Error {
    public enum InternalError: Error {
        case badRequest
        case responseNotFound
    }

    case `internal`(error: InternalError)
    case network(error: Error)
    case server(statusCode: Int, responseError: Response.ResponseError)
}
