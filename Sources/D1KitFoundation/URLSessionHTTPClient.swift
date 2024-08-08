import D1Kit
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import HTTPTypes
import HTTPTypesFoundation

extension URLSession: HTTPClientProtocol {
    public func execute(_ request: HTTPRequest, body: Data?) async throws -> (Data, HTTPResponse) {
        if let body {
          try await self.upload(for: request, from: body)
        } else {
          try await self.data(for: request)
        }
    }
}

extension HTTPClientProtocol where Self == URLSession {
    public static func urlSession(_ urlSession: Self) -> Self {
        return urlSession
    }
}
