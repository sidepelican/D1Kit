import Foundation
import HTTPTypes
import HTTPTypesFoundation

public struct D1Database: Sendable {
    public init(client: D1Client, databaseID: String) {
        precondition(databaseID.isASCII)
        self.client = client
        self.databaseID = databaseID
    }

    public var client: D1Client
    public var databaseID: String

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
        let options = D1ParameterEncodingOptions()
        let params = binds.map { $0.encodeToD1Parameter(options: options)  }
        return try await _query(query, params: params, as: rowType)
    }

    public func query<D: Decodable>(
        _ query: QueryString,
        as rowType: D.Type
    ) async throws -> [D] {
        let options = D1ParameterEncodingOptions()
        return try await _query(
            query.query,
            params: query.params.map({ $0.encodeToD1Parameter(options: options) }),
            as: rowType
        )
    }

    private struct Empty: Decodable {}

    public func query<each B: D1ParameterBindable>(
        raw query: String,
        binds: repeat each B
    ) async throws {
        let options = D1ParameterEncodingOptions()
        var params: [String] = []
        repeat params.append((each binds).encodeToD1Parameter(options: options))
        _ = try await _query(query, params: params, as: Empty.self)
    }

    public func query(_ query: QueryString) async throws {
        let options = D1ParameterEncodingOptions()
        _ = try await _query(
            query.query,
            params: query.params.map({ $0.encodeToD1Parameter(options: options) }),
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
        decoder.dateDecodingStrategy = .custom { decoder in
            let c = try decoder.singleValueContainer()
            let string = try c.decode(String.self)
            guard let date = DateFormatter.sqliteTimestamp.date(from: string) else {
                throw DecodingError.dataCorruptedError(in: c, debugDescription: "\(string) is bad format.")
            }
            return date
        }
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
