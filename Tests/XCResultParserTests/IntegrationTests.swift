import Foundation
import Testing
@testable import XCResultParser

@Suite("Integration Tests")
struct IntegrationTests {
    /// Get path to xcresult fixture bundle
    private func fixtureBundle(_ name: String) -> String {
        let url = Bundle.module.url(forResource: name, withExtension: "xcresult", subdirectory: "Fixtures")!
        return url.path
    }

    @Test("Parse clean build with passing tests")
    func parseCleanBuildPassingTests() async throws {
        let parser = XCResultParser(path: fixtureBundle("clean-build-passing-tests"))
        let result = try await parser.parse()

        // Verify build results
        let buildResults = try #require(result.buildResults)
        #expect(buildResults.status == "succeeded")
        #expect(buildResults.errorCount == 0)
        #expect(buildResults.warningCount == 0)
        #expect(buildResults.analyzerWarningCount == 0)
        #expect(buildResults.allIssues.isEmpty)

        // Verify test results
        let testResults = try #require(result.testResults)
        #expect(testResults.failures.isEmpty)
        #expect(!testResults.testNodes.isEmpty)

        let summary = testResults.summary
        #expect(summary.failedCount == 0)
        #expect(summary.skippedCount == 0)
        #expect(summary.passedCount == summary.totalCount)
        #expect(summary.totalCount > 0)
    }

    @Test("Parse build warnings and test failures")
    func parseBuildWarningsTestFailures() async throws {
        let parser = XCResultParser(path: fixtureBundle("build-warnings-test-failures"))
        let result = try await parser.parse()

        // Verify build results
        let buildResults = try #require(result.buildResults)
        #expect(buildResults.status == "succeeded")
        #expect(buildResults.warningCount > 0 || buildResults.errorCount > 0 || buildResults.analyzerWarningCount > 0)

        // Verify warnings have correct severity
        for warning in buildResults.warnings {
            #expect(warning.severity == .warning)
        }

        // Verify analyzer warnings have correct severity
        for warning in buildResults.analyzerWarnings {
            #expect(warning.severity == .warning)
        }

        // Verify all issues combined
        let allIssues = buildResults.allIssues
        #expect(!allIssues.isEmpty)

        // Verify test results
        let testResults = try #require(result.testResults)
        #expect(!testResults.failures.isEmpty)

        // Verify at least one failure has a source location
        let failuresWithLocation = testResults.failures.filter { $0.sourceLocation != nil }
        #expect(failuresWithLocation.count > 0)

        // Verify failure details
        for failure in testResults.failures {
            #expect(!failure.testName.isEmpty)
            #expect(!failure.testClass.isEmpty)
            #expect(!failure.message.isEmpty)
        }

        // Verify summary has mixed results
        let summary = testResults.summary
        #expect(summary.totalCount > 0)
        #expect(summary.failedCount > 0)
        #expect(summary.passedCount > 0)
        // May have skipped and expected failures depending on the fixture
    }

    @Test("Parse build errors")
    func parseBuildErrors() async throws {
        let parser = XCResultParser(path: fixtureBundle("build-errors"))
        let result = try await parser.parse()

        // Verify build results
        let buildResults = try #require(result.buildResults)
        #expect(buildResults.status == "failed")

        // Verify we have issues (errors or warnings or both)
        let allIssues = buildResults.allIssues
        #expect(!allIssues.isEmpty)

        // Verify at least one issue has error severity or at least we have some issues
        let errorsWithFailureSeverity = allIssues.filter { $0.severity == .failure }
        #expect(errorsWithFailureSeverity.count > 0 || buildResults.errorCount > 0)

        // Verify at least one issue has a source location
        let issuesWithLocation = allIssues.filter { $0.sourceLocation != nil }
        #expect(issuesWithLocation.count > 0)
    }

    @Test("Parse analyzer warnings only")
    func parseAnalyzerWarningsOnly() async throws {
        let parser = XCResultParser(path: fixtureBundle("analyzer-warnings-only"))
        let result = try await parser.parse()

        // Verify build results
        let buildResults = try #require(result.buildResults)
        #expect(buildResults.status == "succeeded")

        // Verify no errors (build succeeded)
        #expect(buildResults.errorCount == 0)

        // If there are analyzer warnings, verify they have correct severity
        for warning in buildResults.analyzerWarnings {
            #expect(warning.severity == .warning)
        }

        // Verify test results (all pass)
        let testResults = try #require(result.testResults)
        #expect(testResults.failures.isEmpty)

        let summary = testResults.summary
        #expect(summary.failedCount == 0)
    }
}
