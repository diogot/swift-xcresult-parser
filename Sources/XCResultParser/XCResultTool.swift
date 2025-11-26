import Foundation

/// Internal actor wrapping xcrun xcresulttool commands
actor XCResultTool {
    let path: String

    init(path: String) {
        self.path = path
    }

    /// Execute xcresulttool and return the JSON data
    private func execute(arguments: [String]) async throws -> Data {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["xcresulttool"] + arguments + ["--path", path, "--compact"]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        do {
            try process.run()
        } catch {
            throw XCResultParserError.xcresulttoolNotFound
        }

        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errorData = stderr.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw XCResultParserError.xcresulttoolFailed(errorMessage.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return stdout.fileHandleForReading.readDataToEndOfFile()
    }

    /// Get build results from the xcresult bundle
    func getBuildResults() async throws -> BuildResults {
        let data = try await execute(arguments: ["get", "build-results"])
        do {
            return try JSONDecoder().decode(BuildResults.self, from: data)
        } catch {
            throw XCResultParserError.invalidJSON(error.localizedDescription)
        }
    }

    /// Get test results from the xcresult bundle
    func getTestResults() async throws -> TestResults {
        let data = try await execute(arguments: ["get", "test-results", "tests"])
        do {
            let response = try JSONDecoder().decode(TestResultsResponse.self, from: data)
            return response.toTestResults()
        } catch {
            throw XCResultParserError.invalidJSON(error.localizedDescription)
        }
    }
}
