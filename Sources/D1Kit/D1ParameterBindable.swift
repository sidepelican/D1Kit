import Foundation

public protocol D1ParameterBindable: Sendable {
    func encodeToD1Parameter() -> String
}

extension String: D1ParameterBindable {
    public func encodeToD1Parameter() -> String {
        self
    }
}

extension Substring: D1ParameterBindable {
    public func encodeToD1Parameter() -> String {
        String(self)
    }
}

extension Date: D1ParameterBindable {
    public func encodeToD1Parameter() -> String {
        DateFormatter.sqlite.string(from: self)
    }
}
