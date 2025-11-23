/// Test result with resilient decoding for forward compatibility
public enum TestResult: Sendable, Equatable {
    case passed
    case failed
    case skipped
    case expectedFailure
    case unknown(String)

    public var rawValue: String {
        switch self {
        case .passed: "Passed"
        case .failed: "Failed"
        case .skipped: "Skipped"
        case .expectedFailure: "Expected Failure"
        case .unknown(let value): value
        }
    }
}

extension TestResult: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "Passed": self = .passed
        case "Failed": self = .failed
        case "Skipped": self = .skipped
        case "Expected Failure": self = .expectedFailure
        default: self = .unknown(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
