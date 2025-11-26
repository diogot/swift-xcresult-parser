import Foundation
import Testing
@testable import XCResultParser

@Suite("XCResultParser Tests")
struct XCResultParserTests {
    @Test("Bundle not found error")
    func bundleNotFound() async {
        let parser = XCResultParser(path: "/nonexistent/path.xcresult")

        await #expect(throws: XCResultParserError.bundleNotFound("/nonexistent/path.xcresult")) {
            try await parser.parse()
        }
    }

    @Test("Error descriptions are meaningful")
    func errorDescriptions() {
        let errors: [XCResultParserError] = [
            .bundleNotFound("/path"),
            .xcresulttoolNotFound,
            .xcresulttoolFailed("command failed"),
            .invalidJSON("parse error"),
            .noBuildResults,
            .noTestResults
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    @Test("XCResult combines build and test results")
    func xcResultCombination() {
        let buildResults = BuildResults(status: "succeeded")
        let testResults = TestResults(testNodes: [])

        let result = XCResult(buildResults: buildResults, testResults: testResults)

        #expect(result.buildResults != nil)
        #expect(result.testResults != nil)
        #expect(result.buildResults?.status == "succeeded")
    }

    @Test("XCResult with nil results")
    func xcResultNilResults() {
        let result = XCResult()

        #expect(result.buildResults == nil)
        #expect(result.testResults == nil)
    }
}
