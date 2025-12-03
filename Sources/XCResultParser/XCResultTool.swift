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

        // Read output BEFORE waiting to avoid pipe buffer deadlock
        // (if output exceeds ~64KB, the process blocks waiting to write)
        let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errorData = stderr.fileHandleForReading.readDataToEndOfFile()

        // Use non-blocking continuation instead of waitUntilExit() to avoid
        // exhausting Swift's cooperative thread pool when processing multiple bundles
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            process.terminationHandler = { _ in
                continuation.resume()
            }
        }

        if process.terminationStatus != 0 {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw XCResultParserError.xcresulttoolFailed(errorMessage.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        return outputData
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
