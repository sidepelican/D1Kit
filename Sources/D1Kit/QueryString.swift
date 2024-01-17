import Foundation

public struct QueryString {
    @usableFromInline
    var query: String
    @usableFromInline
    var params: [any D1ParameterBindable] = []

    @inlinable
    public init(_ string: some StringProtocol) {
        self.query = string.description
    }
}

extension QueryString: ExpressibleByStringLiteral {
    @inlinable
    public init(stringLiteral value: String) {
        self.init(value)
    }
}

extension QueryString: ExpressibleByStringInterpolation {
    @inlinable
    public init(stringInterpolation: QueryString) {
        self.query = stringInterpolation.query
        self.params = stringInterpolation.params
    }
}

extension QueryString: StringInterpolationProtocol {
    @inlinable
    public init(literalCapacity: Int, interpolationCount: Int) {
        self.query = ""
        self.params.reserveCapacity(interpolationCount)
    }

    @inlinable
    public mutating func appendLiteral(_ literal: String) {
        self.query.append(literal)
    }

    @inlinable
    public mutating func appendInterpolation(raw value: String) {
        self.query.append(value)
    }

    @inlinable
    public mutating func appendInterpolation(literal value: some BinaryInteger) {
        self.query.append(value.description)
    }

    @inlinable
    public mutating func appendInterpolation(literal value: some BinaryFloatingPoint) {
        self.query.append("\(value)")
    }

    @inlinable
    public mutating func appendInterpolation(bind value: any D1ParameterBindable) {
        self.query.append("?")
        self.params.append(value)
    }

    @inlinable
    public mutating func appendInterpolation(binds values: [any D1ParameterBindable]) {
        self.query.append("(")
        self.query.append([String](repeating: "?", count: values.count).joined(separator: ","))
        self.query.append(")")
        self.params.append(contentsOf: values)
    }

    @inlinable
    public mutating func appendInterpolation(_ other: QueryString) {
        self.query.append(other.query)
        self.params.append(contentsOf: other.params)
    }
}

extension QueryString {
    @inlinable
    public static func +(lhs: QueryString, rhs: QueryString) -> QueryString {
        return "\(lhs)\(rhs)"
    }

    @inlinable
    public static func +=(lhs: inout QueryString, rhs: QueryString) {
        lhs.appendInterpolation(rhs)
    }
}

extension Array where Element == QueryString {
    @inlinable
    public func joined(separator: String) -> QueryString {
        let separator = "\(raw: separator)" as QueryString
        return self.first.map { self.dropFirst().lazy.reduce($0) { $0 + separator + $1 } } ?? ""
    }
}
