import Foundation
import D1Kit
import D1KitFoundation
import Testing

@Suite struct D1KitTests {
    var db: D1Database

    init() {
        let env = ProcessInfo.processInfo.environment
        let client = D1Client(
            httpClient: .urlSession,
            accountID: env["ACCOUNT_ID"]!,
            apiToken: env["API_TOKEN"]!
        )
        db = D1Database(client: client, databaseID: env["DATABASE_ID"]!)
    }

    @Test func decode() async throws {
        struct Row: Decodable {
            var intValue: Int
            var textValue: String
            var dateValue: Date
        }
        let rows = try await db.query("""
        SELECT
            1 as "intValue"
            , 'Hello, world!' as "textValue"
            , unixepoch(CURRENT_TIMESTAMP) as "dateValue"
        """, as: Row.self)

        let test = try #require(rows.first)
        #expect(test.intValue == 1)
        #expect(test.textValue == "Hello, world!")
        #expect(abs(test.dateValue.timeIntervalSince1970 - Date().timeIntervalSince1970) < 1.0)
    }

    @Test func rawBinds() async throws {
        struct Row: Decodable {
            var intValue: Int
            var textValue: String
            var dateValue: Date
        }
        let now = Date()
        let rows = try await db.query(
            raw:
            """
            SELECT
                cast(? as integer) as "intValue"
                , ? as "textValue"
                , cast(? as integer) as "dateValue"
            """,
            binds: [String(42), "swift", now],
            as: Row.self
        )
        let test = try #require(rows.first)

        #expect(test.intValue == 42)
        #expect(test.textValue == "swift")
        #expect(abs(test.dateValue.timeIntervalSince1970 - now.timeIntervalSince1970) < 1.0)
    }

    @Test func queryStringBinds() async throws {
        struct Row: Decodable {
            var letter: String
            var intValue: Int
            var doubleValue: Double
            var textValue: String
            var dateValue: Date
        }
        let now = Date()
        let rows = try await db.query("""
        WITH cte(letter) AS
            (VALUES ('a'),('i'),('u'))
        SELECT
            letter
            , \(literal: 42) as "intValue"
            , \(literal: 42.195) as "doubleValue"
            , \(bind: "swift") as "textValue"
            , cast(\(bind: now) as integer) as "dateValue"
        FROM
            cte
        WHERE
            letter IN \(binds: ["a", "i"])
        """, as: Row.self)
        try #require(rows.count == 2)
        #expect(rows[0].letter == "a")
        #expect(rows[1].letter == "i")
        #expect(rows[0].intValue == 42)
        #expect(rows[0].doubleValue == 42.195)
        #expect(rows[0].textValue == "swift")
        #expect(abs(rows[0].dateValue.timeIntervalSince1970 - now.timeIntervalSince1970) < 1.0)
    }

    @Test func emptyResult() async throws {
        try await db.query("""
        PRAGMA quick_check(0)
        """)
    }

    @Test func formatCheck() async throws {
        struct Row: Decodable {
            var bindedValueType: String
            var timestamp: String
            var unixepoch: Double
        }
        let rows = try await db.query("""
        SELECT
            typeof(\(bind: "swift")) as "bindedValueType"
            , CURRENT_TIMESTAMP as timestamp
            , unixepoch(CURRENT_TIMESTAMP) as unixepoch
        """, as: Row.self)

        let test = try #require(rows.first)
        #expect(test.bindedValueType == "text")
        #expect((try? Date(test.timestamp, strategy: .sqliteTimestamp)) != nil)
        #expect(test.unixepoch.remainder(dividingBy: 1) == 0.0)
    }

    @Test func dateCodingStrategy() async throws {
        struct Row: Decodable {
            var now: Date
        }

        let now = Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970))

        var db = db
        db.encodingOptions.dateEncodingStrategy = .secondsSince1970
        db.dateDecodingStrategy = .secondsSince1970

        var test = try await db.query("""
        SELECT
            cast(\(bind: now) as integer) as now
        """, as: Row.self).first

        if let test {
            #expect(test.now == now)
        } else {
            Issue.record()
        }

        db.encodingOptions.dateEncodingStrategy = .millisecondsSince1970
        db.dateDecodingStrategy = .millisecondsSince1970
        test = try await db.query("""
        SELECT
            cast(\(bind: now) as integer) as now
        """, as: Row.self).first

        if let test {
            #expect(test.now == now)
        } else {
            Issue.record()
        }

        db.encodingOptions.dateEncodingStrategy = .iso8601
        db.dateDecodingStrategy = .iso8601
        test = try await db.query("""
        SELECT
            \(bind: now) as now
        """, as: Row.self).first

        if let test {
            #expect(test.now == now)
        } else {
            Issue.record()
        }
    }
}
