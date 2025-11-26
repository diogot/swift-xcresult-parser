/// Utility for traversing test node trees
enum TestNodeTraverser {
    /// Extract all test failures from a test node tree
    static func extractFailures(from nodes: [TestNode]) -> [TestFailure] {
        var failures: [TestFailure] = []
        var context = TraversalContext()
        traverse(nodes: nodes, context: &context, failures: &failures)
        return failures
    }

    /// Compute summary statistics from test nodes
    static func computeSummary(from nodes: [TestNode]) -> TestSummary {
        var stats = SummaryStats()
        countResults(nodes: nodes, stats: &stats)
        return TestSummary(
            totalCount: stats.total,
            passedCount: stats.passed,
            failedCount: stats.failed,
            skippedCount: stats.skipped,
            expectedFailureCount: stats.expectedFailure
        )
    }

    private struct TraversalContext {
        var testClass: String?
        var testName: String?
    }

    private struct SummaryStats {
        var total: Int = 0
        var passed: Int = 0
        var failed: Int = 0
        var skipped: Int = 0
        var expectedFailure: Int = 0
    }

    private static func traverse(nodes: [TestNode], context: inout TraversalContext, failures: inout [TestFailure]) {
        for node in nodes {
            var localContext = context

            switch node.nodeType {
            case .testSuite:
                localContext.testClass = node.name

            case .testCase:
                localContext.testName = node.name

            case .failureMessage:
                if let testName = localContext.testName, let testClass = localContext.testClass {
                    let (location, message) = SourceLocation.fromFailureMessage(node.name)
                    let failure = TestFailure(
                        testName: testName,
                        testClass: testClass,
                        message: message,
                        sourceLocation: location
                    )
                    failures.append(failure)
                }

            default:
                break
            }

            if let children = node.children {
                traverse(nodes: children, context: &localContext, failures: &failures)
            }
        }
    }

    private static func countResults(nodes: [TestNode], stats: inout SummaryStats) {
        for node in nodes {
            if node.nodeType == .testCase, let result = node.result {
                stats.total += 1
                switch result {
                case .passed: stats.passed += 1
                case .failed: stats.failed += 1
                case .skipped: stats.skipped += 1
                case .expectedFailure: stats.expectedFailure += 1
                case .unknown: break
                }
            }

            if let children = node.children {
                countResults(nodes: children, stats: &stats)
            }
        }
    }
}
