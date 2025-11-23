import Foundation
import Testing
@testable import XCResultParser

@Suite("TestResults Tests")
struct TestResultsTests {
    @Test("Decode passing test results")
    func decodePassingTestResults() throws {
        let json = try loadFixture("test-results-pass.json")
        let response = try JSONDecoder().decode(TestResultsResponse.self, from: json)
        let results = response.toTestResults()

        #expect(results.devices.count == 1)
        #expect(results.devices[0].deviceName == "iPhone 16 Pro")
        #expect(results.testNodes.count == 1)
        #expect(results.failures.isEmpty)

        let summary = results.summary
        #expect(summary.totalCount == 2)
        #expect(summary.passedCount == 2)
        #expect(summary.failedCount == 0)
    }

    @Test("Decode test results with failures")
    func decodeTestResultsWithFailures() throws {
        let json = try loadFixture("test-results-failures.json")
        let response = try JSONDecoder().decode(TestResultsResponse.self, from: json)
        let results = response.toTestResults()

        let failures = results.failures
        #expect(failures.count == 2)

        let firstFailure = failures[0]
        #expect(firstFailure.testName == "testAlwaysFails()")
        #expect(firstFailure.testClass == "SampleProjectTests")
        #expect(firstFailure.message == "Issue recorded: This test will always fail")
        #expect(firstFailure.sourceLocation?.file == "SampleProjectTests.swift")
        #expect(firstFailure.sourceLocation?.line == 14)

        let secondFailure = failures[1]
        #expect(secondFailure.testName == "testAnotherFailure()")
        #expect(secondFailure.testClass == "AnotherTestSuite")
        #expect(secondFailure.message == "XCTAssertEqual failed: (\"1\") is not equal to (\"2\")")
        #expect(secondFailure.sourceLocation?.line == 42)
    }

    @Test("Test summary with mixed results")
    func testSummaryMixedResults() throws {
        let json = try loadFixture("test-results-failures.json")
        let response = try JSONDecoder().decode(TestResultsResponse.self, from: json)
        let results = response.toTestResults()

        let summary = results.summary
        #expect(summary.totalCount == 5)
        #expect(summary.passedCount == 1)
        #expect(summary.failedCount == 2)
        #expect(summary.skippedCount == 1)
        #expect(summary.expectedFailureCount == 1)
    }

    private func loadFixture(_ name: String) throws -> Data {
        let url = Bundle.module.url(forResource: name.replacingOccurrences(of: ".json", with: ""), withExtension: "json", subdirectory: "Fixtures")!
        return try Data(contentsOf: url)
    }
}
