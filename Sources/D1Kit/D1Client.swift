#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import HTTPTypes

public struct D1Client: Sendable {
    public init(httpClient: any HTTPClientProtocol, accountID: String, apiToken: String) {
        precondition(accountID.isASCII)
        precondition(apiToken.isASCII)
        self.httpClient = httpClient
        self.accountID = accountID
        self.apiToken = apiToken
    }
    
    public var httpClient: any HTTPClientProtocol
    public var accountID: String
    public var apiToken: String

    internal func execute(_ request: HTTPRequest, body: Data?) async throws -> (Data, HTTPResponse) {
        var request = request
        request.headerFields[.authorization] = "Bearer \(apiToken)"
        return try await httpClient.execute(request, body: body)
    }
}
