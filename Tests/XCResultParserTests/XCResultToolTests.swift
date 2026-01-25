import Foundation
import Testing
@testable import XCResultParser

@Suite("XCResultTool Tests", .serialized)
struct XCResultToolTests {
    /// Get path to xcresult fixture bundle
    private func fixtureBundle(_ name: String) -> String {
        let url = Bundle.module.url(forResource: name, withExtension: "xcresult", subdirectory: "Fixtures")!
        return url.path
    }

    @Test("Process termination completes without hanging", .timeLimit(.minutes(1)))
    func processTerminationCompletes() async throws {
        // This test verifies the fix for the race condition where setting
        // terminationHandler after readDataToEndOfFile() could cause a deadlock
        // if the process had already terminated.
        //
        // The test parses an xcresult bundle and verifies it completes within
        // a reasonable time frame (the .timeLimit trait will fail the test if
        // it takes too long).
        let parser = XCResultParser(path: fixtureBundle("clean-build-passing-tests"))
        let result = try await parser.parse()

        #expect(result.buildResults != nil || result.testResults != nil)
    }

    @Test("Sequential parsing of multiple bundles", .timeLimit(.minutes(1)))
    func sequentialParsingCompletes() async throws {
        // This test verifies that parsing multiple xcresult bundles sequentially
        // doesn't cause issues with process termination.
        let bundles = [
            "clean-build-passing-tests",
            "build-warnings-test-failures",
            "build-errors",
            "analyzer-warnings-only"
        ]

        for bundle in bundles {
            let parser = XCResultParser(path: fixtureBundle(bundle))
            let result = try await parser.parse()
            #expect(result.buildResults != nil || result.testResults != nil,
                    "Bundle \(bundle) should parse successfully")
        }
    }

    @Test("Repeated parsing of same bundle", .timeLimit(.minutes(1)))
    func repeatedParsingStable() async throws {
        // This test verifies that repeatedly parsing xcresult bundles doesn't
        // cause thread exhaustion or memory issues. Each iteration should
        // properly clean up process resources.
        let parser = XCResultParser(path: fixtureBundle("clean-build-passing-tests"))

        for iteration in 1...5 {
            let result = try await parser.parse()
            #expect(result.buildResults != nil || result.testResults != nil,
                    "Iteration \(iteration) should succeed")
        }
    }
}
