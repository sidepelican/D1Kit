import Foundation

public protocol D1ParameterBindable: Sendable {
    func encodeToD1Parameter(options: D1ParameterEncodingOptions) -> String
}

extension String: D1ParameterBindable {
    public func encodeToD1Parameter(options: D1ParameterEncodingOptions) -> String {
        self
    }
}

extension Substring: D1ParameterBindable {
    public func encodeToD1Parameter(options: D1ParameterEncodingOptions) -> String {
        String(self)
    }
}

extension Date: D1ParameterBindable {
    public func encodeToD1Parameter(options: D1ParameterEncodingOptions) -> String {
        switch options.dateEncodingStrategy {
        case .secondsSince1970:
            return Int(timeIntervalSince1970).description
        case .millisecondsSince1970:
            return Int(timeIntervalSince1970 * 1000).description
        case .iso8601:
            return ISO8601DateFormatter().string(from: self)
        case .formatted(let formatter):
            return formatter.string(from: self)
        case .custom(let custom):
            return custom(self)
        }
    }
}
