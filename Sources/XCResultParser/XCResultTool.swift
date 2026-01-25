import Foundation

/// Internal actor wrapping xcrun xcresulttool commands
actor XCResultTool {
    let path: String

    init(path: String) {
        self.path = path
    }

    /// Execute xcresulttool and return the JSON data
    private func execute(arguments: [String]) async throws -> Data {
        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory
        let uuid = UUID().uuidString
        let stdoutFile = tempDir.appendingPathComponent("xcresulttool-\(uuid).stdout")
        let stderrFile = tempDir.appendingPathComponent("xcresulttool-\(uuid).stderr")

        defer {
            try? fileManager.removeItem(at: stdoutFile)
            try? fileManager.removeItem(at: stderrFile)
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = [
            "-c",
            "xcrun \"$@\" > \"\(stdoutFile.path)\" 2> \"\(stderrFile.path)\"",
            "--",
            "xcresulttool"
        ] + arguments + ["--path", path, "--compact"]

        do {
            try process.run()
        } catch {
            throw XCResultParserError.xcresulttoolNotFound
        }

        process.waitUntilExit()

        let outputData: Data
        do {
            outputData = try Data(contentsOf: stdoutFile)
        } catch {
            throw XCResultParserError.xcresulttoolFailed("Failed to read stdout: \(error.localizedDescription)")
        }

        if process.terminationStatus != 0 {
            let errorData = (try? Data(contentsOf: stderrFile)) ?? Data()
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
