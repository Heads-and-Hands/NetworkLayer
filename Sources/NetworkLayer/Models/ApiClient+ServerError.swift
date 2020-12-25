import Foundation

extension ApiClient {
    public enum ServerError: String, Decodable, Error {
        case some
        case parseError
    }
}
