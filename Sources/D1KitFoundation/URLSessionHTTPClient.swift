import D1Kit
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import HTTPTypes
import HTTPTypesFoundation

private enum HTTPTypeConversionError: Error {
    case failedToConvertHTTPRequestToURLRequest
    case failedToConvertURLResponseToHTTPResponse
}

extension URLSession: HTTPClientProtocol {
    public func execute(_ request: HTTPRequest, body: Data?) async throws -> (Data, HTTPResponse) {
        guard var urlRequest = URLRequest(httpRequest: request) else {
            throw HTTPTypeConversionError.failedToConvertHTTPRequestToURLRequest
        }
        urlRequest.httpBody = body
        let (data, urlResponse) = try await self.data(for: urlRequest)
        guard let response = (urlResponse as? HTTPURLResponse)?.httpResponse else {
            throw HTTPTypeConversionError.failedToConvertURLResponseToHTTPResponse
        }
        return (data, response)
    }
}

extension HTTPClientProtocol where Self == URLSession {
    public static func urlSession(_ urlSession: Self) -> Self {
        return urlSession
    }
}
