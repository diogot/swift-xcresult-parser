# swift-xcresult-parser

A type-safe Swift library for parsing Xcode `.xcresult` bundles and extracting build warnings, errors, and test failures in a structured format.

[![Swift](https://img.shields.io/badge/Swift-6.2+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2015+-blue.svg)](https://developer.apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- **Parse xcresult bundles**: Extract structured data from Xcode result bundles
- **Zero external dependencies**: Uses only `xcrun xcresulttool` (ships with Xcode)
- **Type-safe output**: Strongly-typed Swift models with resilient decoding
- **Async/await support**: Modern Swift concurrency
- **Forward compatible**: Handles unknown enum values gracefully for future Xcode versions

## Requirements

- Swift 6.2+
- macOS 15+
- Xcode 16+

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/diogot/swift-xcresult-parser.git", from: "1.0.0")
]
```

Then add `XCResultParser` to your target dependencies:

```swift
.target(name: "YourTarget", dependencies: ["XCResultParser"])
```

## Usage

### Basic Usage

```swift
import XCResultParser

let parser = XCResultParser(path: "path/to/test.xcresult")
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
```

### Parse Only Build Results

```swift
let parser = XCResultParser(path: "path/to/test.xcresult")
let buildResults = try await parser.parseBuildResults()

print("Warnings: \(buildResults.warningCount)")
print("Errors: \(buildResults.errorCount)")
```

### Parse Only Test Results

```swift
let parser = XCResultParser(path: "path/to/test.xcresult")
let testResults = try await parser.parseTestResults()

let summary = testResults.summary
print("Total: \(summary.totalCount)")
print("Passed: \(summary.passedCount)")
print("Failed: \(summary.failedCount)")
```

### Source Location Handling

The library normalizes source locations from two different xcresulttool formats:

```swift
// Build issues provide absolute paths
if let location = buildIssue.sourceLocation {
    let relativePath = location.relativePath(from: "/path/to/repo")
    print("\(relativePath):\(location.line)")
}

// Test failures provide filename and line
for failure in testResults.failures {
    if let location = failure.sourceLocation {
        print("\(location.file):\(location.line)")
    }
}
```

## API Reference

### XCResultParser

```swift
public final class XCResultParser: Sendable {
    public init(path: String)
    public func parse() async throws -> XCResult
    public func parseBuildResults() async throws -> BuildResults
    public func parseTestResults() async throws -> TestResults
}
```

### Models

- `XCResult` - Combined build and test results
- `BuildResults` - Build action results with warnings, errors, analyzer warnings
- `BuildIssue` - Individual build warning or error with source location
- `TestResults` - Test execution results with device info and test node tree
- `TestNode` - Hierarchical test node (test plan, bundle, suite, case, etc.)
- `TestFailure` - Flattened test failure for easy reporting
- `SourceLocation` - File path, line, and optional column
- `TestResult` - Test outcome (passed, failed, skipped, expectedFailure)
- `TestNodeType` - Node type in test hierarchy
- `Severity` - Issue severity level (notice, warning, failure)

## License

MIT License - see [LICENSE](LICENSE) for details.
