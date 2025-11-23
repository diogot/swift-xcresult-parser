import Foundation

/// Parser for Xcode xcresult bundles
public final class XCResultParser: Sendable {
    private let path: String
    private let tool: XCResultTool

    /// Initialize with path to xcresult bundle
    /// - Parameter path: Path to the .xcresult bundle
    public init(path: String) {
        self.path = path
        self.tool = XCResultTool(path: path)
    }

    /// Parse both build and test results
    /// - Returns: Combined XCResult with build and test results
    /// - Throws: XCResultParserError if parsing fails
    public func parse() async throws -> XCResult {
        try validateBundle()

        async let buildResults = parseBuildResultsInternal()
        async let testResults = parseTestResultsInternal()

        return XCResult(
            buildResults: try? await buildResults,
            testResults: try? await testResults
        )
    }

    /// Parse only build results (warnings, errors)
    /// - Returns: BuildResults containing warnings and errors
    /// - Throws: XCResultParserError if parsing fails
    public func parseBuildResults() async throws -> BuildResults {
        try validateBundle()
        return try await tool.getBuildResults()
    }

    /// Parse only test results (failures)
    /// - Returns: TestResults containing test node tree and failures
    /// - Throws: XCResultParserError if parsing fails
    public func parseTestResults() async throws -> TestResults {
        try validateBundle()
        return try await tool.getTestResults()
    }

    private func parseBuildResultsInternal() async throws -> BuildResults {
        try await tool.getBuildResults()
    }

    private func parseTestResultsInternal() async throws -> TestResults {
        try await tool.getTestResults()
    }

    private func validateBundle() throws {
        let fileManager = FileManager.default
        var isDirectory: ObjCBool = false

        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory),
              isDirectory.boolValue else {
            throw XCResultParserError.bundleNotFound(path)
        }
    }
}
