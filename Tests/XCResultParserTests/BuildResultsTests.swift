import Foundation
import Testing
@testable import XCResultParser

@Suite("BuildResults Tests")
struct BuildResultsTests {
    @Test("Decode clean build results")
    func decodeCleanBuildResults() throws {
        let json = try loadFixture("build-results-clean.json")
        let results = try JSONDecoder().decode(BuildResults.self, from: json)

        #expect(results.status == "succeeded")
        #expect(results.warningCount == 0)
        #expect(results.errorCount == 0)
        #expect(results.analyzerWarningCount == 0)
        #expect(results.warnings.isEmpty)
        #expect(results.errors.isEmpty)
        #expect(results.analyzerWarnings.isEmpty)
        #expect(results.allIssues.isEmpty)
    }

    @Test("Decode build results with warnings")
    func decodeBuildResultsWithWarnings() throws {
        let json = try loadFixture("build-results-warnings.json")
        let results = try JSONDecoder().decode(BuildResults.self, from: json)

        #expect(results.status == "succeeded")
        #expect(results.warningCount == 2)
        #expect(results.warnings.count == 2)
        #expect(results.analyzerWarningCount == 1)
        #expect(results.analyzerWarnings.count == 1)
        #expect(results.errorCount == 0)
        #expect(results.errors.isEmpty)
        #expect(results.allIssues.count == 3)
    }

    @Test("Decode build results with errors")
    func decodeBuildResultsWithErrors() throws {
        let json = try loadFixture("build-results-errors.json")
        let results = try JSONDecoder().decode(BuildResults.self, from: json)

        #expect(results.status == "failed")
        #expect(results.errorCount == 2)
        #expect(results.errors.count == 2)
        #expect(results.warningCount == 1)
        #expect(results.warnings.count == 1)
    }

    @Test("Decode build results with unknown fields (forward compatibility)")
    func decodeBuildResultsWithUnknownFields() throws {
        let json = try loadFixture("build-results-unknown-fields.json")
        let results = try JSONDecoder().decode(BuildResults.self, from: json)

        #expect(results.status == "succeeded")
        #expect(results.warningCount == 0)
        #expect(results.errorCount == 0)
    }

    @Test("Build issue source location parsing")
    func buildIssueSourceLocation() throws {
        let json = try loadFixture("build-results-warnings.json")
        let results = try JSONDecoder().decode(BuildResults.self, from: json)

        let warning = results.warnings[0]
        #expect(warning.sourceLocation != nil)
        #expect(warning.sourceLocation?.file == "/Users/dev/SampleProject/Sources/ContentView.swift")
        #expect(warning.sourceLocation?.line == 15)
    }

    @Test("Build issue severity mapping")
    func buildIssueSeverity() {
        let error = BuildIssue(issueType: "Error", message: "test")
        let warning = BuildIssue(issueType: "Warning", message: "test")
        let analyzer = BuildIssue(issueType: "Analyzer Warning", message: "test")
        let other = BuildIssue(issueType: "Unknown", message: "test")

        #expect(error.severity == .failure)
        #expect(warning.severity == .warning)
        #expect(analyzer.severity == .warning)
        #expect(other.severity == .notice)
    }

    private func loadFixture(_ name: String) throws -> Data {
        let url = Bundle.module.url(forResource: name.replacingOccurrences(of: ".json", with: ""), withExtension: "json", subdirectory: "Fixtures")!
        return try Data(contentsOf: url)
    }
}
