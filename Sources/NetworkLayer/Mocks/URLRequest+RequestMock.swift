import Foundation

extension URLRequest {
    private enum Constants {
        static let mockFileName = "X-Mock-file-name"
        static let mockStatusCode = "X-Mock-status-code"
    }

    var mockFileName: String? {
        value(forHTTPHeaderField: Constants.mockFileName)
    }

    var mockStatusCode: Int {
        Int(value(forHTTPHeaderField: Constants.mockStatusCode) ?? "200") ?? 200
    }

    mutating func set(mock: RequestMock) {
        let jsonFileName: String
        let responseStatusCode: String

        switch mock {
        case let .default(path, statusCode, method):
            responseStatusCode = String(statusCode ?? 200)

            let urlPath = path?
                .replacingOccurrences(of: "/", with: "_")
                .trimmingCharacters(in: CharacterSet(charactersIn: "_"))

            jsonFileName = [responseStatusCode, method.lowercased(), urlPath]
                .compactMap { $0 }
                .joined(separator: "_")
        case let .custom(fileName, statusCode):
            responseStatusCode = String(statusCode)
            jsonFileName = fileName
        }

        addValue(jsonFileName, forHTTPHeaderField: Constants.mockFileName)
        addValue(responseStatusCode, forHTTPHeaderField: Constants.mockStatusCode)
    }
}
