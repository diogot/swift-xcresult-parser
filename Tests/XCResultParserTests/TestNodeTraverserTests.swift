import Testing
@testable import XCResultParser

@Suite("TestNodeTraverser Tests")
struct TestNodeTraverserTests {
    @Test("Extract failures from nested tree")
    func extractFailuresFromNestedTree() {
        let nodes = [
            TestNode(
                nodeType: .testPlan,
                name: "Plan",
                result: .failed,
                children: [
                    TestNode(
                        nodeType: .unitTestBundle,
                        name: "Bundle",
                        result: .failed,
                        children: [
                            TestNode(
                                nodeType: .testSuite,
                                name: "MyTests",
                                result: .failed,
                                children: [
                                    TestNode(
                                        nodeType: .testCase,
                                        name: "testFailing()",
                                        result: .failed,
                                        children: [
                                            TestNode(
                                                nodeType: .failureMessage,
                                                name: "MyTests.swift:10: Assertion failed"
                                            )
                                        ]
                                    )
                                ]
                            )
                        ]
                    )
                ]
            )
        ]

        let failures = TestNodeTraverser.extractFailures(from: nodes)

        #expect(failures.count == 1)
        #expect(failures[0].testName == "testFailing()")
        #expect(failures[0].testClass == "MyTests")
        #expect(failures[0].message == "Assertion failed")
        #expect(failures[0].sourceLocation?.file == "MyTests.swift")
        #expect(failures[0].sourceLocation?.line == 10)
    }

    @Test("Extract multiple failures from different suites")
    func extractMultipleFailures() {
        let nodes = [
            TestNode(
                nodeType: .testSuite,
                name: "Suite1",
                children: [
                    TestNode(
                        nodeType: .testCase,
                        name: "test1()",
                        result: .failed,
                        children: [
                            TestNode(nodeType: .failureMessage, name: "File1.swift:5: Error 1")
                        ]
                    )
                ]
            ),
            TestNode(
                nodeType: .testSuite,
                name: "Suite2",
                children: [
                    TestNode(
                        nodeType: .testCase,
                        name: "test2()",
                        result: .failed,
                        children: [
                            TestNode(nodeType: .failureMessage, name: "File2.swift:10: Error 2")
                        ]
                    )
                ]
            )
        ]

        let failures = TestNodeTraverser.extractFailures(from: nodes)
        #expect(failures.count == 2)
        #expect(failures[0].testClass == "Suite1")
        #expect(failures[1].testClass == "Suite2")
    }

    @Test("Compute summary from test nodes")
    func computeSummary() {
        let nodes = [
            TestNode(
                nodeType: .testSuite,
                name: "Suite",
                children: [
                    TestNode(nodeType: .testCase, name: "testPass()", result: .passed),
                    TestNode(nodeType: .testCase, name: "testFail()", result: .failed),
                    TestNode(nodeType: .testCase, name: "testSkip()", result: .skipped),
                    TestNode(nodeType: .testCase, name: "testExpected()", result: .expectedFailure)
                ]
            )
        ]

        let summary = TestNodeTraverser.computeSummary(from: nodes)

        #expect(summary.totalCount == 4)
        #expect(summary.passedCount == 1)
        #expect(summary.failedCount == 1)
        #expect(summary.skippedCount == 1)
        #expect(summary.expectedFailureCount == 1)
    }

    @Test("Empty nodes returns empty failures")
    func emptyNodes() {
        let failures = TestNodeTraverser.extractFailures(from: [])
        #expect(failures.isEmpty)

        let summary = TestNodeTraverser.computeSummary(from: [])
        #expect(summary.totalCount == 0)
    }
}
