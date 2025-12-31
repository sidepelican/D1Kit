#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

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
            return self.ISO8601Format()
#if !canImport(FoundationEssentials)
        case .formatted(let formatter):
            return formatter.string(from: self)
#endif
        case .custom(let custom):
            return custom(self, options)
        }
    }
}
