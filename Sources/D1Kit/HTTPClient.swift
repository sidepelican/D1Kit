#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import HTTPTypes

public protocol HTTPClientProtocol: Sendable {
    func execute(_ request: HTTPRequest, body: Data?) async throws -> (Data, HTTPResponse)
}
