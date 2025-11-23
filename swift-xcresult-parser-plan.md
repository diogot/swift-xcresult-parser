# Swift XCResult Parser Plan (Phase 1)

## Overview

This document outlines the design and implementation of `swift-xcresult-parser`, an independent Swift library for parsing Xcode `.xcresult` bundles and extracting build warnings, errors, and test failures in a structured format.

## Goals

1. **Parse xcresult bundles**: Extract structured data from Xcode result bundles
2. **Zero external dependencies**: Use only `xcrun xcresulttool` (ships with Xcode)
3. **Type-safe output**: Provide strongly-typed Swift models with resilient decoding
4. **PRReporterKit compatible**: Output types that map directly to `Annotation`
5. **Async/await support**: Modern Swift concurrency
6. **Forward compatible**: Handle unknown enum values gracefully for future Xcode versions

## Non-Goals

- Modifying xcresult bundles
- Code coverage parsing (future enhancement)
- Performance metrics parsing (future enhancement)
- Supporting Xcode versions older than 16

## Requirements

| Requirement | Value |
|-------------|-------|
| Swift | 6.2+ |
| Platform | macOS 15+ |
| Xcode | 16+ (tested with Xcode 26) |
| xcresulttool | Version 24056+ |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   swift-xcresult-parser                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────┐    │
│  │                   XCResultParser                     │    │
│  │  - parse() -> XCResult                              │    │
│  │  - parseBuildResults() -> BuildResults              │    │
│  │  - parseTestResults() -> TestResults                │    │
│  └─────────────────────────────────────────────────────┘    │
│                            │                                 │
│                            ▼                                 │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                    XCResultTool                      │    │
│  │  - getBuildResults(path:) -> JSON                   │    │
│  │  - getTestResults(path:) -> JSON                    │    │
│  │  - Uses: xcrun xcresulttool                         │    │
│  └─────────────────────────────────────────────────────┘    │
│                            │                                 │
│                            ▼                                 │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                      Models                          │    │
│  │  - XCResult (combined build + test)                 │    │
│  │  - BuildResults, BuildIssue                         │    │
│  │  - TestResults, TestNode, TestFailure               │    │
│  │  - SourceLocation (file, line, column)              │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Data Source: xcresulttool

The library wraps `xcrun xcresulttool` which provides JSON output. Verified with xcresulttool version 24056 (Xcode 26).

### Build Results Command

```bash
xcrun xcresulttool get build-results --path <path> --compact
```

**Real Output Example (Xcode 26):**
```json
{
  "actionTitle": "Testing project SampleProject with scheme SampleProject",
  "analyzerWarningCount": 0,
  "analyzerWarnings": [],
  "destination": {
    "architecture": "arm64",
    "deviceId": "C9052A05-F7A1-4E33-880E-3FB3485C3F49",
    "deviceName": "iPhone 16 Pro",
    "modelName": "iPhone 16 Pro",
    "osBuildNumber": "23B86",
    "osVersion": "26.1",
    "platform": "iOS Simulator"
  },
  "endTime": 1763935357.829,
  "errorCount": 0,
  "errors": [],
  "startTime": 1763935325.829,
  "status": "succeeded",
  "warningCount": 0,
  "warnings": []
}
```

**Issue Schema (for warnings/errors arrays):**
```json
{
  "issueType": "string",
  "message": "string",
  "targetName": "string?",
  "sourceURL": "string?",     // file:///absolute/path/to/File.swift#StartingLineNumber
  "className": "string?"
}
```

### Test Results Command

```bash
xcrun xcresulttool get test-results tests --path <path> --compact
```

**Real Output Example (Xcode 26):**
```json
{
  "devices": [
    {
      "architecture": "arm64",
      "deviceId": "C9052A05-F7A1-4E33-880E-3FB3485C3F49",
      "deviceName": "iPhone 16 Pro",
      "modelName": "iPhone 16 Pro",
      "osBuildNumber": "23B86",
      "osVersion": "26.1",
      "platform": "iOS Simulator"
    }
  ],
  "testNodes": [
    {
      "children": [...],
      "name": "SampleProject",
      "nodeType": "Test Plan",
      "result": "Failed"
    }
  ],
  "testPlanConfigurations": [
    {"configurationId": "1", "configurationName": "Configuration 1"}
  ]
}
```

**TestNode Schema (recursive tree):**
```json
{
  "nodeType": "Test Case | Failure Message | Test Suite | ...",
  "name": "string",
  "result": "Passed | Failed | Skipped | Expected Failure",
  "nodeIdentifier": "string?",
  "nodeIdentifierURL": "string?",
  "duration": "string?",
  "durationInSeconds": 0.0,
  "children": [TestNode]
}
```

**Important: Failure Message Format**

Test failure source locations are embedded in the `name` field of `Failure Message` nodes:

```json
{
  "name": "SampleProjectTests.swift:14: Issue recorded: This test will always fail",
  "nodeType": "Failure Message"
}
```

Format: `<filename>:<line>: <message>`

This must be parsed to extract source location (see Source Location Handling below).

## Models

### Core Types

```swift
/// Combined result from an xcresult bundle
public struct XCResult: Sendable {
    public let buildResults: BuildResults?
    public let testResults: TestResults?

    /// All issues as annotations (for PRReporterKit)
    public var annotations: [Annotation] { ... }
}

/// Build action results
public struct BuildResults: Sendable, Codable {
    public let actionTitle: String?
    public let status: String?
    public let warningCount: Int
    public let errorCount: Int
    public let analyzerWarningCount: Int
    public let warnings: [BuildIssue]
    public let errors: [BuildIssue]
    public let analyzerWarnings: [BuildIssue]

    /// All issues combined
    public var allIssues: [BuildIssue] { ... }
}

/// A build warning, error, or analyzer warning
public struct BuildIssue: Sendable, Codable {
    public let issueType: String
    public let message: String
    public let targetName: String?
    public let sourceURL: String?
    public let className: String?

    /// Parsed source location from sourceURL
    public var sourceLocation: SourceLocation? { ... }

    /// Severity level for annotations
    public var severity: Severity { ... }
}

/// Test execution results
public struct TestResults: Sendable {
    public let testNodes: [TestNode]
    public let devices: [Device]

    /// All test failures
    public var failures: [TestFailure] { ... }

    /// Summary statistics
    public var summary: TestSummary { ... }
}

/// Hierarchical test node
public struct TestNode: Sendable, Codable {
    public let nodeIdentifier: String?
    public let nodeType: TestNodeType
    public let name: String
    public let result: TestResult?
    public let duration: String?
    public let durationInSeconds: Double?
    public let children: [TestNode]?
}

/// Flattened test failure for reporting
public struct TestFailure: Sendable {
    public let testName: String           // e.g., "testExample()"
    public let testClass: String          // e.g., "MyTests"
    public let message: String            // Failure message
    public let sourceLocation: SourceLocation?
}

/// Source code location
public struct SourceLocation: Sendable, Equatable {
    public let file: String               // Relative path
    public let line: Int
    public let column: Int?
}

/// Issue/annotation severity
public enum Severity: Sendable {
    case notice
    case warning
    case failure
}
```

### Enums (Resilient Decoding)

All enums use custom decoding to handle unknown values from future Xcode versions:

```swift
/// Test result with resilient decoding for forward compatibility
public enum TestResult: Sendable, Equatable {
    case passed
    case failed
    case skipped
    case expectedFailure
    case unknown(String)  // Captures unknown values for forward compatibility

    public var rawValue: String {
        switch self {
        case .passed: "Passed"
        case .failed: "Failed"
        case .skipped: "Skipped"
        case .expectedFailure: "Expected Failure"
        case .unknown(let value): value
        }
    }
}

extension TestResult: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "Passed": self = .passed
        case "Failed": self = .failed
        case "Skipped": self = .skipped
        case "Expected Failure": self = .expectedFailure
        default: self = .unknown(value)  // Forward compatible
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

/// Test node type with resilient decoding for forward compatibility
public enum TestNodeType: Sendable, Equatable {
    case testPlan
    case unitTestBundle
    case uiTestBundle
    case testSuite
    case testCase
    case device
    case testPlanConfiguration
    case arguments
    case repetition
    case testCaseRun
    case failureMessage
    case sourceCodeReference
    case attachment
    case expression
    case testValue
    case runtimeWarning
    case unknown(String)  // Captures unknown values for forward compatibility

    public var rawValue: String {
        switch self {
        case .testPlan: "Test Plan"
        case .unitTestBundle: "Unit test bundle"
        case .uiTestBundle: "UI test bundle"
        case .testSuite: "Test Suite"
        case .testCase: "Test Case"
        case .device: "Device"
        case .testPlanConfiguration: "Test Plan Configuration"
        case .arguments: "Arguments"
        case .repetition: "Repetition"
        case .testCaseRun: "Test Case Run"
        case .failureMessage: "Failure Message"
        case .sourceCodeReference: "Source Code Reference"
        case .attachment: "Attachment"
        case .expression: "Expression"
        case .testValue: "Test Value"
        case .runtimeWarning: "Runtime Warning"
        case .unknown(let value): value
        }
    }
}

extension TestNodeType: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        switch value {
        case "Test Plan": self = .testPlan
        case "Unit test bundle": self = .unitTestBundle
        case "UI test bundle": self = .uiTestBundle
        case "Test Suite": self = .testSuite
        case "Test Case": self = .testCase
        case "Device": self = .device
        case "Test Plan Configuration": self = .testPlanConfiguration
        case "Arguments": self = .arguments
        case "Repetition": self = .repetition
        case "Test Case Run": self = .testCaseRun
        case "Failure Message": self = .failureMessage
        case "Source Code Reference": self = .sourceCodeReference
        case "Attachment": self = .attachment
        case "Expression": self = .expression
        case "Test Value": self = .testValue
        case "Runtime Warning": self = .runtimeWarning
        default: self = .unknown(value)  // Forward compatible
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
```

## Source Location Handling

Source locations come from two different formats that must be normalized:

### Build Issues: `sourceURL` field

Format: `file:///absolute/path/to/File.swift#LineNumber`

```swift
/// Parse sourceURL from build issues
func parseSourceURL(_ urlString: String) -> SourceLocation? {
    // Example: "file:///Users/dev/MyApp/Sources/File.swift#42"
    guard urlString.hasPrefix("file://") else { return nil }

    let parts = urlString.dropFirst(7).split(separator: "#", maxSplits: 1)
    let absolutePath = String(parts[0])
    let line = parts.count > 1 ? Int(parts[1]) : nil

    return SourceLocation(
        absolutePath: absolutePath,
        line: line ?? 1,
        column: nil
    )
}
```

### Test Failures: Embedded in `name` field

Format: `<filename>:<line>: <message>`

```swift
/// Parse failure message name from test results
func parseFailureMessage(_ name: String) -> (location: SourceLocation?, message: String) {
    // Example: "SampleProjectTests.swift:14: Issue recorded: This test will always fail"
    // Regex: ^(.+\.swift):(\d+): (.+)$

    let pattern = #"^(.+\.swift):(\d+): (.+)$"#
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)) else {
        return (nil, name)  // No location found, return full name as message
    }

    let filename = String(name[Range(match.range(at: 1), in: name)!])
    let line = Int(name[Range(match.range(at: 2), in: name)!])!
    let message = String(name[Range(match.range(at: 3), in: name)!])

    return (SourceLocation(filename: filename, line: line, column: nil), message)
}
```

### Path Relativization

For GitHub annotations, paths must be relative to the repository root. The parser provides both:

```swift
public struct SourceLocation: Sendable, Equatable {
    /// Original path (absolute for build issues, filename-only for test failures)
    public let originalPath: String

    /// Line number (1-based)
    public let line: Int

    /// Column number (optional, 1-based)
    public let column: Int?

    /// Convert to relative path for annotations
    /// - Parameter repositoryRoot: The repository root directory
    /// - Returns: Path relative to repository root, or original if not under root
    public func relativePath(from repositoryRoot: String) -> String {
        guard originalPath.hasPrefix(repositoryRoot) else {
            return originalPath  // Already relative or different root
        }
        var relative = String(originalPath.dropFirst(repositoryRoot.count))
        if relative.hasPrefix("/") {
            relative = String(relative.dropFirst())
        }
        return relative
    }
}
```

**Normalization Rules:**

1. Build issues provide absolute paths via `file://` URL - extract and relativize
2. Test failures provide filename only - search for matching file in repo
3. Missing line numbers default to 1
4. Missing columns are reported as `nil` (PRReporterKit handles this)
5. Invalid/unparseable locations return `nil` (annotation skipped)

## API Design

### Primary Interface

```swift
/// Parser for Xcode xcresult bundles
public final class XCResultParser: Sendable {

    /// Initialize with path to xcresult bundle
    public init(path: String)

    /// Parse both build and test results
    public func parse() async throws -> XCResult

    /// Parse only build results (warnings, errors)
    public func parseBuildResults() async throws -> BuildResults

    /// Parse only test results (failures)
    public func parseTestResults() async throws -> TestResults
}
```

### Usage Examples

```swift
// Basic usage
let parser = XCResultParser(path: "reports/test.xcresult")
let result = try await parser.parse()

// Access build issues
for issue in result.buildResults?.allIssues ?? [] {
    print("\(issue.severity): \(issue.message)")
    if let loc = issue.sourceLocation {
        print("  at \(loc.file):\(loc.line)")
    }
}

// Access test failures
for failure in result.testResults?.failures ?? [] {
    print("FAIL: \(failure.testClass).\(failure.testName)")
    print("  \(failure.message)")
}

// Get annotations for PRReporterKit
let annotations = result.annotations
```

### PRReporterKit Integration

```swift
import PRReporterKit
import XCResultParser

// Parse xcresult
let parser = XCResultParser(path: "reports/test.xcresult")
let result = try await parser.parse()

// Convert to PRReporterKit annotations
let annotations: [Annotation] = result.buildResults?.allIssues.compactMap { issue in
    guard let loc = issue.sourceLocation else { return nil }
    return Annotation(
        path: loc.file,
        line: loc.line,
        endLine: nil,
        column: loc.column,
        level: issue.severity.toAnnotationLevel(),
        message: issue.message,
        title: issue.issueType
    )
} ?? []

// Report to GitHub
let reporter = CheckRunReporter(context: context, name: "Build", identifier: "build")
try await reporter.report(annotations)
```

## Implementation Phases

### Phase 1A: Project Setup

**Tasks:**
- [ ] Create new Swift package repository `swift-xcresult-parser`
- [ ] Set up Package.swift with platforms (macOS 15+, Swift 6.2)
- [ ] Add GitHub Actions CI workflow (with Xcode 16+ runners)
- [ ] Add MIT license and README

**Package.swift:**
```swift
// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "swift-xcresult-parser",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "XCResultParser", targets: ["XCResultParser"])
    ],
    targets: [
        .target(name: "XCResultParser"),
        .testTarget(name: "XCResultParserTests", dependencies: ["XCResultParser"])
    ]
)
```

### Phase 1B: Core Models

**Files:**
- `Sources/XCResultParser/Models/XCResult.swift`
- `Sources/XCResultParser/Models/BuildResults.swift`
- `Sources/XCResultParser/Models/BuildIssue.swift`
- `Sources/XCResultParser/Models/TestResults.swift`
- `Sources/XCResultParser/Models/TestNode.swift`
- `Sources/XCResultParser/Models/TestFailure.swift`
- `Sources/XCResultParser/Models/TestSummary.swift`
- `Sources/XCResultParser/Models/SourceLocation.swift`
- `Sources/XCResultParser/Models/Severity.swift`
- `Sources/XCResultParser/Models/Device.swift`

**Features:**
- All models are `Sendable` and `Codable` where applicable
- Resilient enum decoding with `.unknown(String)` fallback
- `SourceLocation` parsing from both `file://` URLs and failure message format
- Test node traversal helpers
- Severity mapping logic

### Phase 1C: xcresulttool Wrapper

**Files:**
- `Sources/XCResultParser/XCResultTool.swift`
- `Sources/XCResultParser/XCResultToolError.swift`

**Features:**
- Execute `xcrun xcresulttool` commands
- JSON parsing with error handling
- Async/await interface
- Validation of xcresult bundle existence

```swift
internal actor XCResultTool {
    let path: String

    func getBuildResults() async throws -> BuildResults
    func getTestResults() async throws -> TestResultsResponse
}
```

### Phase 1D: Parser Implementation

**Files:**
- `Sources/XCResultParser/XCResultParser.swift`
- `Sources/XCResultParser/TestNodeTraverser.swift`

**Features:**
- Main `XCResultParser` class
- Test node tree traversal for extracting failures
- Source location extraction from failure nodes
- Combine build and test results into `XCResult`

### Phase 1E: Testing

**Test Files:**
- `Tests/XCResultParserTests/BuildResultsTests.swift`
- `Tests/XCResultParserTests/TestResultsTests.swift`
- `Tests/XCResultParserTests/SourceLocationTests.swift`
- `Tests/XCResultParserTests/XCResultParserTests.swift`
- `Tests/XCResultParserTests/Fixtures/` - Sample JSON responses

**Test Strategy:**
- Unit tests with mock JSON responses
- Integration tests with real xcresult bundles (in CI)
- Source location URL parsing edge cases
- Test node traversal correctness

### Phase 1F: Documentation & Release

**Tasks:**
- [ ] Complete README with usage examples
- [ ] Add inline documentation (DocC compatible)
- [ ] Create CHANGELOG.md
- [ ] Tag v1.0.0 release
- [ ] Publish to Swift Package Index

## Error Handling

```swift
public enum XCResultParserError: Error, LocalizedError {
    case bundleNotFound(String)
    case xcresulttoolNotFound
    case xcresulttoolFailed(String)
    case invalidJSON(String)
    case noBuildResults
    case noTestResults

    public var errorDescription: String? { ... }
}
```

## Testing Strategy

### Unit Tests

1. **Model Parsing Tests**
   - Parse valid JSON responses
   - Handle missing optional fields
   - Parse various issue types

2. **Source Location Tests**
   - Parse `file:///path/to/File.swift#42` URLs
   - Parse failure message format `File.swift:14: message`
   - Handle missing line numbers (default to 1)
   - Handle missing/malformed URLs gracefully
   - Path relativization with various root directories

3. **Test Node Traversal Tests**
   - Extract failures from nested tree
   - Handle various node types
   - Extract source references from failure messages

4. **Resilient Decoding Tests (Critical)**
   - Unknown `TestResult` values decode to `.unknown("NewValue")`
   - Unknown `TestNodeType` values decode to `.unknown("NewType")`
   - Missing optional fields don't fail decoding
   - Extra unknown fields are ignored
   - Malformed JSON returns appropriate errors

### Integration Tests (CI with Xcode 16+)

1. **Real xcresult Bundle Tests**
   - Generate xcresult with `xcodebuild test` in CI
   - Test with intentional build warnings
   - Test with intentional test failures
   - Verify correct extraction matches xcodebuild output

2. **Schema Drift Detection**
   - Compare parsed output against xcresulttool --schema
   - Alert on new fields (for future enhancement opportunities)
   - Verify no decoding failures with current Xcode version

### Fixtures

Store sample JSON responses in `Tests/Fixtures/`:
- `build-results-clean.json` - No issues
- `build-results-warnings.json` - Build warnings with sourceURL
- `build-results-errors.json` - Build errors with sourceURL
- `test-results-pass.json` - All tests pass
- `test-results-failures.json` - Test failures with embedded locations
- `test-results-unknown-types.json` - Unknown enum values for resilience testing
- `build-results-unknown-fields.json` - Extra fields for forward compatibility testing

### CI Workflow

```yaml
# .github/workflows/test.yml
name: Tests
on: [push, pull_request]

jobs:
  test:
    runs-on: macos-26
    steps:
      - uses: actions/checkout@v4

      - name: Run Unit Tests
        run: swift test

      - name: Generate Test xcresult
        run: |
          cd TestFixtures/SampleProject
          xcodebuild test \
            -scheme SampleProject \
            -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
            -resultBundlePath ../../tmp/integration-test.xcresult \
            || true  # Allow test failures

      - name: Run Integration Tests
        run: swift test --filter IntegrationTests
        env:
          XCRESULT_PATH: tmp/integration-test.xcresult
```

## Dependencies

**External Tools:**
- `xcrun xcresulttool` - Part of Xcode Command Line Tools

**Swift Packages:**
- Foundation only (no external dependencies)

## File Structure

```
swift-xcresult-parser/
├── Package.swift
├── README.md
├── LICENSE
├── CHANGELOG.md
├── Sources/
│   └── XCResultParser/
│       ├── XCResultParser.swift
│       ├── XCResultTool.swift
│       ├── XCResultToolError.swift
│       ├── TestNodeTraverser.swift
│       └── Models/
│           ├── XCResult.swift
│           ├── BuildResults.swift
│           ├── BuildIssue.swift
│           ├── TestResults.swift
│           ├── TestNode.swift
│           ├── TestFailure.swift
│           ├── TestSummary.swift
│           ├── SourceLocation.swift
│           ├── Severity.swift
│           └── Device.swift
└── Tests/
    └── XCResultParserTests/
        ├── BuildResultsTests.swift
        ├── TestResultsTests.swift
        ├── SourceLocationTests.swift
        ├── TestNodeTraverserTests.swift
        ├── ResilientDecodingTests.swift
        ├── XCResultParserTests.swift
        ├── IntegrationTests.swift
        └── Fixtures/
            ├── build-results-clean.json
            ├── build-results-warnings.json
            ├── build-results-errors.json
            ├── build-results-unknown-fields.json
            ├── test-results-pass.json
            ├── test-results-failures.json
            └── test-results-unknown-types.json
```

## Timeline Estimate

| Phase | Description |
|-------|-------------|
| 1A | Project setup |
| 1B | Core models |
| 1C | xcresulttool wrapper |
| 1D | Parser implementation |
| 1E | Testing |
| 1F | Documentation & release |

## Future Enhancements

1. **Code Coverage Parsing** - Extract coverage data from xcresult
2. **Performance Metrics** - Parse performance test results
3. **Attachments** - Extract screenshots and other attachments
4. **Diff Support** - Compare two xcresult bundles
5. **CLI Tool** - Command-line interface for quick inspection
6. **Code Snippets** - Extract source code context for issues (requires reading source files, xcresulttool doesn't provide this)
7. **Retried Test Detection** - Identify tests that failed then passed on retry (need to investigate xcresulttool support)

## References

- [xcresulttool documentation](https://developer.apple.com/documentation/xcode/using-xcode-with-continuous-integration-and-testing-frameworks)
- [swift-pr-reporter](https://github.com/diogot/swift-pr-reporter)
- [PRReporterKit API](https://github.com/diogot/swift-pr-reporter)
