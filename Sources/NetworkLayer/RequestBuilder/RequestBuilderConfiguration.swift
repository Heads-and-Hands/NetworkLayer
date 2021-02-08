import Foundation

public protocol RequestBuilderConfiguration {
    var serverHost: String { get }
    var debugMode: Bool { get }
}
