/// Summary statistics for test results
public struct TestSummary: Sendable, Equatable {
    public let totalCount: Int
    public let passedCount: Int
    public let failedCount: Int
    public let skippedCount: Int
    public let expectedFailureCount: Int

    public init(
        totalCount: Int,
        passedCount: Int,
        failedCount: Int,
        skippedCount: Int,
        expectedFailureCount: Int
    ) {
        self.totalCount = totalCount
        self.passedCount = passedCount
        self.failedCount = failedCount
        self.skippedCount = skippedCount
        self.expectedFailureCount = expectedFailureCount
    }
}
