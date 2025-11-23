import Foundation
import Testing
@testable import XCResultParser

@Suite("Integration Tests", .disabled("Requires XCRESULT_PATH environment variable"))
struct IntegrationTests {
    @Test("Parse real xcresult bundle")
    func parseRealBundle() async throws {
        guard let path = ProcessInfo.processInfo.environment["XCRESULT_PATH"] else {
            throw TestError.missingEnvironmentVariable
        }

        let parser = XCResultParser(path: path)
        let result = try await parser.parse()

        #expect(result.buildResults != nil || result.testResults != nil)
    }

    @Test("Parse build results from real bundle")
    func parseBuildResults() async throws {
        guard let path = ProcessInfo.processInfo.environment["XCRESULT_PATH"] else {
            throw TestError.missingEnvironmentVariable
        }

        let parser = XCResultParser(path: path)
        let buildResults = try await parser.parseBuildResults()

        #expect(buildResults.status != nil)
    }

    @Test("Parse test results from real bundle")
    func parseTestResults() async throws {
        guard let path = ProcessInfo.processInfo.environment["XCRESULT_PATH"] else {
            throw TestError.missingEnvironmentVariable
        }

        let parser = XCResultParser(path: path)
        let testResults = try await parser.parseTestResults()

        #expect(!testResults.testNodes.isEmpty)
    }

    enum TestError: Error {
        case missingEnvironmentVariable
    }
}
