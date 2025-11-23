/// Test execution results from xcresulttool
public struct TestResults: Sendable, Equatable {
    public let testNodes: [TestNode]
    public let devices: [Device]

    public init(testNodes: [TestNode], devices: [Device] = []) {
        self.testNodes = testNodes
        self.devices = devices
    }

    /// All test failures extracted from the test node tree
    public var failures: [TestFailure] {
        TestNodeTraverser.extractFailures(from: testNodes)
    }

    /// Summary statistics computed from test nodes
    public var summary: TestSummary {
        TestNodeTraverser.computeSummary(from: testNodes)
    }
}

/// Response structure for decoding xcresulttool test results
struct TestResultsResponse: Codable {
    let testNodes: [TestNode]
    let devices: [Device]?

    func toTestResults() -> TestResults {
        TestResults(testNodes: testNodes, devices: devices ?? [])
    }
}
