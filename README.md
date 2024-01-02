# D1Kit

A Swift client for Cloudflare's D1 service.

## Example

```swift
import D1Kit
import D1KitFoundation

let client = D1Client(
    httpClient: .urlSession(.shared),
    accountID: "YOUR_ACCOUNT_ID",
    apiToken: "YOUR_API_TOKEN"
)
let db = D1Database(client: client, databaseID: "YOUR_DATABASE_ID")

struct Row: Decodable {
    var id: Int
    var name: String
}

let rows = try await db.query(
    "SELECT * FROM users WHERE name = \(bind: "Bob")",
    as: Row.self
)
```

## Installation

D1Kit supports the Swift Package Manager.
To integrate it into your project, follow the common Swift Package Manager setup process.

## Usage with URLSession

To use `D1Kit` with `URLSession`, add the `D1KitFoundation` dependency and pass a `URLSession` instance as the `httpClient` when initializing `D1Client`.

## Usage with AsyncHTTPClient

To use `D1Kit` with `AsyncHTTPClient`, you will need to conform `AsyncHTTPClient.HTTPClient` to `D1Kit.HTTPClientProtocol`. Below is an example code snippet:

```swift
import AsyncHTTPClient
import D1Kit
import Foundation
import HTTPTypes

extension HTTPClient: D1Kit.HTTPClientProtocol {
    public func execute(_ request: HTTPRequest, body: Data?) async throws -> (Data, HTTPResponse) {
        guard let url = request.url else {
            throw HTTPClientError.invalidURL
        }
        var req = HTTPClientRequest(url: url.absoluteString)
        req.headers = .init(request.headerFields.map { ($0.name.rawName, $0.value) })
        req.method = .init(rawValue: request.method.rawValue)
        req.body = body.map { .bytes($0) }

        let res = try await execute(req, timeout: .seconds(15))
        let resData = Data(buffer: try await res.body.collect(upTo: .max))
        
        var response = HTTPResponse(status: .init(code: numericCast(res.status.code)))
        response.headerFields = HTTPFields()
        
        for header in res.headers {
            if let name = HTTPField.Name(header.name) {
                response.headerFields[name] = header.value
            }
        }
        
        return (resData, response)
    }
}
```
