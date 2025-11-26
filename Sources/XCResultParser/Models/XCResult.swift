/// Combined result from an xcresult bundle
public struct XCResult: Sendable, Equatable {
    public let buildResults: BuildResults?
    public let testResults: TestResults?

    public init(buildResults: BuildResults? = nil, testResults: TestResults? = nil) {
        self.buildResults = buildResults
        self.testResults = testResults
    }
}
