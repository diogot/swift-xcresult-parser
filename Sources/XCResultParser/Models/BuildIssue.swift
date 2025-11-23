/// A build warning, error, or analyzer warning
public struct BuildIssue: Sendable, Codable, Equatable {
    public let issueType: String
    public let message: String
    public let targetName: String?
    public let sourceURL: String?
    public let className: String?

    public init(
        issueType: String,
        message: String,
        targetName: String? = nil,
        sourceURL: String? = nil,
        className: String? = nil
    ) {
        self.issueType = issueType
        self.message = message
        self.targetName = targetName
        self.sourceURL = sourceURL
        self.className = className
    }

    /// Parsed source location from sourceURL
    public var sourceLocation: SourceLocation? {
        guard let sourceURL else { return nil }
        return SourceLocation.fromSourceURL(sourceURL)
    }

    /// Severity level for annotations based on issue type
    public var severity: Severity {
        switch issueType.lowercased() {
        case "error": .failure
        case "warning": .warning
        case "analyzer warning": .warning
        default: .notice
        }
    }
}
