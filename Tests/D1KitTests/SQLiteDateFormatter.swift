import Foundation

extension DateFormatter {
    @ThreadLocal static var sqliteTimestamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.timeZone = .init(secondsFromGMT: 0)
        return f
    }()
}

@propertyWrapper
struct ThreadLocal<Value> {
    private let defaultValue: () -> Value
    private let name: String

    init(wrappedValue: @autoclosure @escaping () -> Value) {
        self.defaultValue = wrappedValue
        self.name = UUID().uuidString
    }

    var wrappedValue: Value {
        get {
            let dict = Thread.current.threadDictionary
            if let value = dict[name] {
                return value as! Value
            }
            let value = defaultValue()
            dict[name] = value
            return value
        }

        set {
            let dict = Thread.current.threadDictionary
            dict[name] = newValue
        }
    }

    @available(*, unavailable, message: "Use ThreadLocal to static property.")
    static subscript(
        _enclosingInstance object: Never,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Never, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Never, Self>
    ) -> Value {
        get { }
    }
}
