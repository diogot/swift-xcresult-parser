/// Flattened test failure for reporting
public struct TestFailure: Sendable, Equatable {
    /// Test method name, e.g., "testExample()"
    public let testName: String

    /// Test class name, e.g., "MyTests"
    public let testClass: String

    /// Failure message
    public let message: String

    /// Source code location of the failure
    public let sourceLocation: SourceLocation?

    public init(
        testName: String,
        testClass: String,
        message: String,
        sourceLocation: SourceLocation? = nil
    ) {
        self.testName = testName
        self.testClass = testClass
        self.message = message
        self.sourceLocation = sourceLocation
    }
}
