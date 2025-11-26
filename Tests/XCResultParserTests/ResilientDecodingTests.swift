import Foundation
import Testing
@testable import XCResultParser

@Suite("Resilient Decoding Tests")
struct ResilientDecodingTests {
    @Test("Unknown TestResult decodes to unknown case")
    func unknownTestResult() throws {
        let json = """
        "Future Result Type"
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(TestResult.self, from: json)
        #expect(result == .unknown("Future Result Type"))
        #expect(result.rawValue == "Future Result Type")
    }

    @Test("Known TestResult values decode correctly")
    func knownTestResults() throws {
        let cases: [(String, TestResult)] = [
            ("\"Passed\"", .passed),
            ("\"Failed\"", .failed),
            ("\"Skipped\"", .skipped),
            ("\"Expected Failure\"", .expectedFailure)
        ]

        for (json, expected) in cases {
            let result = try JSONDecoder().decode(TestResult.self, from: json.data(using: .utf8)!)
            #expect(result == expected)
        }
    }

    @Test("Unknown TestNodeType decodes to unknown case")
    func unknownTestNodeType() throws {
        let json = """
        "Future Node Type"
        """.data(using: .utf8)!

        let nodeType = try JSONDecoder().decode(TestNodeType.self, from: json)
        #expect(nodeType == .unknown("Future Node Type"))
        #expect(nodeType.rawValue == "Future Node Type")
    }

    @Test("Known TestNodeType values decode correctly")
    func knownTestNodeTypes() throws {
        let cases: [(String, TestNodeType)] = [
            ("\"Test Plan\"", .testPlan),
            ("\"Unit test bundle\"", .unitTestBundle),
            ("\"UI test bundle\"", .uiTestBundle),
            ("\"Test Suite\"", .testSuite),
            ("\"Test Case\"", .testCase),
            ("\"Failure Message\"", .failureMessage)
        ]

        for (json, expected) in cases {
            let nodeType = try JSONDecoder().decode(TestNodeType.self, from: json.data(using: .utf8)!)
            #expect(nodeType == expected)
        }
    }

    @Test("Test results with unknown types decode successfully")
    func testResultsWithUnknownTypes() throws {
        let json = try loadFixture("test-results-unknown-types.json")
        let response = try JSONDecoder().decode(TestResultsResponse.self, from: json)
        let results = response.toTestResults()

        #expect(results.testNodes.count == 1)

        let planNode = results.testNodes[0]
        #expect(planNode.nodeType == .testPlan)

        let bundleNode = planNode.children?[0]
        #expect(bundleNode?.nodeType == .unknown("Future Test Bundle Type"))
        #expect(bundleNode?.result == .unknown("Future Result Type"))
    }

    @Test("TestResult encodes correctly")
    func testResultEncodes() throws {
        let encoder = JSONEncoder()

        let passed = try encoder.encode(TestResult.passed)
        #expect(String(data: passed, encoding: .utf8) == "\"Passed\"")

        let unknown = try encoder.encode(TestResult.unknown("Custom"))
        #expect(String(data: unknown, encoding: .utf8) == "\"Custom\"")
    }

    @Test("TestNodeType encodes correctly")
    func testNodeTypeEncodes() throws {
        let encoder = JSONEncoder()

        let testCase = try encoder.encode(TestNodeType.testCase)
        #expect(String(data: testCase, encoding: .utf8) == "\"Test Case\"")

        let unknown = try encoder.encode(TestNodeType.unknown("Custom Type"))
        #expect(String(data: unknown, encoding: .utf8) == "\"Custom Type\"")
    }

    private func loadFixture(_ name: String) throws -> Data {
        let url = Bundle.module.url(forResource: name.replacingOccurrences(of: ".json", with: ""), withExtension: "json", subdirectory: "Fixtures")!
        return try Data(contentsOf: url)
    }
}
