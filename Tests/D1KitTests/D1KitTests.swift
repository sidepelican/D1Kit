import Foundation
@testable import D1Kit
import D1KitFoundation
import XCTest

final class D1KitTests: XCTestCase {
    var db: D1Database!

    override func setUp() {
        super.setUp()

        let env = ProcessInfo.processInfo.environment
        let client = D1Client(
            httpClient: .urlSession(.shared),
            accountID: env["ACCOUNT_ID"]!,
            apiToken: env["API_TOKEN"]!
        )
        db = D1Database(client: client, databaseID: env["DATABASE_ID"]!)
    }

    func testDecode() async throws {
        struct Row: Decodable {
            var intValue: Int
            var textValue: String
            var dateValue: Date
        }
        let test = try await db.query("""
        SELECT
            1 as "intValue"
            , 'Hello, world!' as "textValue"
            , CURRENT_TIMESTAMP as "dateValue"
        """, as: Row.self).first
        if let test {
            XCTAssertEqual(test.intValue, 1)
            XCTAssertEqual(test.textValue, "Hello, world!")
            XCTAssertEqual(test.dateValue.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 1.0)
        } else {
            XCTFail()
        }
    }

    func testRawBinds() async throws {
        struct Row: Decodable {
            var intValue: Int
            var textValue: String
            var dateValue: Date
        }
        let now = Date()
        let test = try await db.query(raw:
        """
        SELECT
            cast(? as integer) as "intValue"
            , ? as "textValue"
            , ? as "dateValue"
        """,
        binds: [String(42), "swift", now], as: Row.self).first

        if let test {
            XCTAssertEqual(test.intValue, 42)
            XCTAssertEqual(test.textValue, "swift")
            XCTAssertEqual(test.dateValue.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 1.0)
        } else {
            XCTFail()
        }
    }

    func testQueryStringBinds() async throws {
        struct Row: Decodable {
            var letter: String
            var intValue: Int
            var doubleValue: Double
            var textValue: String
            var dateValue: Date
        }
        let now = Date()
        let test = try await db.query("""
        WITH cte(letter) AS
            (VALUES ('a'),('i'),('u'))
        SELECT
            letter
            , \(literal: 42) as "intValue"
            , \(literal: 42.195) as "doubleValue"
            , \(bind: "swift") as "textValue"
            , \(bind: now) as "dateValue"
        FROM
            cte
        WHERE
            letter IN \(binds: ["a", "i"])
        """, as: Row.self)
        if test.count == 2 {
            XCTAssertEqual(test[0].letter, "a")
            XCTAssertEqual(test[1].letter, "i")
            XCTAssertEqual(test[0].intValue, 42)
            XCTAssertEqual(test[0].doubleValue, 42.195)
            XCTAssertEqual(test[0].textValue, "swift")
            XCTAssertEqual(test[0].dateValue.timeIntervalSince1970, now.timeIntervalSince1970, accuracy: 1.0)
        } else {
            XCTFail()
        }
    }

    func testEmptyResult() async throws {
        try await db.query("""
        PRAGMA quick_check(0)
        """)
    }

    func testFormatCheck() async throws {
        struct Row: Decodable {
            var bindedValueType: String
            var timestamp: String
            var unixepoch: Double
        }
        let test = try await db.query("""
        SELECT
            typeof(\(bind: "swift")) as "bindedValueType"
            , CURRENT_TIMESTAMP as timestamp
            , unixepoch(CURRENT_TIMESTAMP) as unixepoch
        """, as: Row.self).first

        if let test {
            XCTAssertEqual(test.bindedValueType, "text")
            XCTAssertNotNil(DateFormatter.sqliteTimestamp.date(from: test.timestamp))
            XCTAssertEqual(test.unixepoch.remainder(dividingBy: 1), 0.0, accuracy: 0.0)
        } else {
            XCTFail()
        }
    }

    func testDateCodingStrategy() async throws {
        struct Row: Decodable {
            var now: Date
        }

        let now = Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970))

        var db = db!
        
        db.encodingOptions.dateEncodingStrategy = .secondsSince1970
        db.dateDecodingStrategy = .secondsSince1970
        var test = try await db.query("""
        SELECT
            cast(\(bind: now) as integer) as now
        """, as: Row.self).first

        if let test {
            XCTAssertEqual(test.now, now)
        } else {
            XCTFail()
        }

        db.encodingOptions.dateEncodingStrategy = .millisecondsSince1970
        db.dateDecodingStrategy = .millisecondsSince1970
        test = try await db.query("""
        SELECT
            cast(\(bind: now) as integer) as now
        """, as: Row.self).first

        if let test {
            XCTAssertEqual(test.now, now)
        } else {
            XCTFail()
        }

        db.encodingOptions.dateEncodingStrategy = .iso8601
        db.dateDecodingStrategy = .iso8601
        test = try await db.query("""
        SELECT
            \(bind: now) as now
        """, as: Row.self).first

        if let test {
            XCTAssertEqual(test.now, now)
        } else {
            XCTFail()
        }
    }
}
