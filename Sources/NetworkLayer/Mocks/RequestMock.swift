import Foundation

public enum RequestMock {
    case `default`(_ path: String?, _ statusCode: Int?, _ method: String)
    case custom(_ fileName: String, _ statusCode: Int)
}
