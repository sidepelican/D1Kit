public struct D1Error: Error, CustomStringConvertible {
    public var errors: [CodeMessage]
    public var messages: [CodeMessage]

    public var description: String {
        "D1Error{ errors=\(errors), messages=\(messages) }"
    }
}

public struct CodeMessage: Decodable, Sendable, CustomStringConvertible {
    public var code: Int
    public var message: String

    public var description: String {
        "{code=\(code), message=\(message)}"
    }
}
