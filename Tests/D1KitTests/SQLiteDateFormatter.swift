import Foundation

extension ParseStrategy where Self == Date.ISO8601FormatStyle {
    static var sqliteTimestamp: Date.ISO8601FormatStyle {
        Date.ISO8601FormatStyle.iso8601(
            timeZone: .init(secondsFromGMT: 0)!,
            includingFractionalSeconds: false,
            dateSeparator: .dash,
            dateTimeSeparator: .space,
            timeSeparator: .colon
        )
    }
}
