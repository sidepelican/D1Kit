import Foundation

public protocol D1ParameterEncodingOptionKey {
    associatedtype Value
    static var defaultValue: Self.Value { get }
}

public struct D1ParameterEncodingOptions: Sendable {
    private var storage: [ObjectIdentifier: any Sendable] = [:]

    public init() {}

    public subscript<Key: D1ParameterEncodingOptionKey>(key: Key.Type) -> Key.Value {
        get {
            let i = ObjectIdentifier(key)
            if let value = storage[i] as? Key.Value {
                return value
            }
            return Key.defaultValue
        }
        set {
            let i = ObjectIdentifier(key)
            storage[i] = newValue
        }
    }
}

public enum D1DateEncodingStrategy {
    case secondsSince1970
    case millisecondsSince1970
    case iso8601
    case formatted(DateFormatter)
    @preconcurrency case custom(@Sendable (Date) -> String)
}

public struct D1DateEncodingStrategyKey: D1ParameterEncodingOptionKey {
    public static var defaultValue: D1DateEncodingStrategy {
        .secondsSince1970
    }
}

extension D1ParameterEncodingOptions {
    public var dateEncodingStrategy: D1DateEncodingStrategy {
        get { self[D1DateEncodingStrategyKey.self] }
        set { self[D1DateEncodingStrategyKey.self] = newValue }
    }
}
