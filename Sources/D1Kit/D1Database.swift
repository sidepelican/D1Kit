#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import HTTPTypes

public struct D1Database: Sendable {
    public init(client: D1Client, databaseID: String) {
        precondition(databaseID.isASCII)
        self.client = client
        self.databaseID = databaseID
    }

    public var client: D1Client
    public var databaseID: String
    public var encodingOptions: D1ParameterEncodingOptions = .init()
    public var dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .secondsSince1970

    private func databaseURL() -> URL {
        return URL(string: "https://api.cloudflare.com/client/v4/accounts/\(client.accountID)/d1/database/\(databaseID)")!
    }

    struct QueryReqeust: Encodable {
        var params: [String]
        var sql: String
    }

    struct QueryResponse<Row: Decodable>: Decodable {
        struct Result: Decodable {
            var results: [Row]
            var success: Bool
        }
        var result: [Result]?
        var errors: [CodeMessage]?
        var messages: [CodeMessage]?
        var success: Bool
    }

    public func query<D: Decodable>(
        raw query: String,
        binds: [any D1ParameterBindable],
        as rowType: D.Type
    ) async throws -> [D] {
        let params = binds.map { $0.encodeToD1Parameter(options: encodingOptions)  }
        return try await _query(query, params: params, as: rowType)
    }

    public func query<D: Decodable>(
        _ query: QueryString,
        as rowType: D.Type
    ) async throws -> [D] {
        return try await _query(
            query.query,
            params: query.params.map({ $0.encodeToD1Parameter(options: encodingOptions) }),
            as: rowType
        )
    }

    private struct Empty: Decodable {}

    public func query<each B: D1ParameterBindable>(
        raw query: String,
        binds: repeat each B
    ) async throws {
        var params: [String] = []
        repeat params.append((each binds).encodeToD1Parameter(options: encodingOptions))
        _ = try await _query(query, params: params, as: Empty.self)
    }

    public func query(_ query: QueryString) async throws {
        _ = try await _query(
            query.query,
            params: query.params.map({ $0.encodeToD1Parameter(options: encodingOptions) }),
            as: Empty.self
        )
    }

    private func _query<D: Decodable>(
        _ query: String,
        params: [String],
        as rowType: D.Type
    ) async throws -> [D] {
        let request = HTTPRequest(
            method: .post,
            url: databaseURL().appendingPathComponent("query"),
            headerFields: [
                .contentType: "application/json",
            ]
        )
        let encoder = JSONEncoder()
        let requestBody = try encoder.encode(QueryReqeust(params: params, sql: query))

        let (body, response) = try await client.execute(request, body: requestBody)

//        print(String(data: body, encoding: .utf8) ?? "<empty>")

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        let responseBody = try decoder.decode(QueryResponse<D>.self, from: body)
        switch response.status {
        case .ok:
            return responseBody.result?.first?.results ?? []
        default:
            throw D1Error(
                errors: responseBody.errors ?? [],
                messages: responseBody.messages ?? []
            )
        }
    }
}
