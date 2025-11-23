/// Build action results from xcresulttool
public struct BuildResults: Sendable, Codable, Equatable {
    public let actionTitle: String?
    public let status: String?
    public let warningCount: Int
    public let errorCount: Int
    public let analyzerWarningCount: Int
    public let warnings: [BuildIssue]
    public let errors: [BuildIssue]
    public let analyzerWarnings: [BuildIssue]

    public init(
        actionTitle: String? = nil,
        status: String? = nil,
        warningCount: Int = 0,
        errorCount: Int = 0,
        analyzerWarningCount: Int = 0,
        warnings: [BuildIssue] = [],
        errors: [BuildIssue] = [],
        analyzerWarnings: [BuildIssue] = []
    ) {
        self.actionTitle = actionTitle
        self.status = status
        self.warningCount = warningCount
        self.errorCount = errorCount
        self.analyzerWarningCount = analyzerWarningCount
        self.warnings = warnings
        self.errors = errors
        self.analyzerWarnings = analyzerWarnings
    }

    /// All issues combined (errors, warnings, analyzer warnings)
    public var allIssues: [BuildIssue] {
        errors + warnings + analyzerWarnings
    }
}
