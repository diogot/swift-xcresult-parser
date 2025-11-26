/// Test node type with resilient decoding for forward compatibility
public enum TestNodeType: Sendable, Equatable {
    case testPlan
    case unitTestBundle
    case uiTestBundle
    case testSuite
    case testCase
    case device
    case testPlanConfiguration
    case arguments
    case repetition
    case testCaseRun
    case failureMessage
    case sourceCodeReference
    case attachment
    case expression
    case testValue
    case runtimeWarning
    case unknown(String)

    public var rawValue: String {
        switch self {
        case .testPlan: "Test Plan"
        case .unitTestBundle: "Unit test bundle"
        case .uiTestBundle: "UI test bundle"
        case .testSuite: "Test Suite"
        case .testCase: "Test Case"
        case .device: "Device"
        case .testPlanConfiguration: "Test Plan Configuration"
        case .arguments: "Arguments"
        case .repetition: "Repetition"
        case .testCaseRun: "Test Case Run"
        case .failureMessage: "Failure Message"
        case .sourceCodeReference: "Source Code Reference"
        case .attachment: "Attachment"
        case .expression: "Expression"
        case .testValue: "Test Value"
        case .runtimeWarning: "Runtime Warning"
        case .unknown(let value): value
        }
    }
}

extension TestNodeType: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "Test Plan": self = .testPlan
        case "Unit test bundle": self = .unitTestBundle
        case "UI test bundle": self = .uiTestBundle
        case "Test Suite": self = .testSuite
        case "Test Case": self = .testCase
        case "Device": self = .device
        case "Test Plan Configuration": self = .testPlanConfiguration
        case "Arguments": self = .arguments
        case "Repetition": self = .repetition
        case "Test Case Run": self = .testCaseRun
        case "Failure Message": self = .failureMessage
        case "Source Code Reference": self = .sourceCodeReference
        case "Attachment": self = .attachment
        case "Expression": self = .expression
        case "Test Value": self = .testValue
        case "Runtime Warning": self = .runtimeWarning
        default: self = .unknown(value)
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
