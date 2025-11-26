# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Swift library for parsing Xcode `.xcresult` bundles. Extracts build warnings/errors and test failures in a structured, type-safe format. Zero external dependencies (uses only `xcrun xcresulttool` from Xcode).

**Requirements:** Swift 6.2+, macOS 15+, Xcode 16+

**Status:** Phase 1 implemented. Design document at `swift-xcresult-parser-plan.md`.

## Build & Test Commands

```bash
swift build           # Build the package
swift test            # Run unit tests
swift test --filter IntegrationTests  # Integration tests (CI only)
```

## Architecture

Three-layer design:

1. **XCResultParser** (public API) - Main entry point for parsing xcresult bundles
2. **XCResultTool** (internal actor) - Wraps `xcrun xcresulttool` commands
3. **Models** - Strongly-typed Swift structs/enums with resilient decoding

Data flow:
```
XCResultParser.parse(path:)
    → XCResultTool (executes xcrun xcresulttool get build-results/test-results)
    → JSON decoding into models
    → XCResult (unified container)
```

## Key Design Principles

- All types are `Sendable` for concurrency safety
- Resilient enum decoding: unknown values captured as `.unknown(String)` for forward compatibility with future Xcode versions
- Source location normalization from two xcresulttool formats:
  - Build issues: `file:///path/File.swift#LineNumber`
  - Test failures: parsed from failure message (`File.swift:42: message`)
- Zero external dependencies (Foundation only)

## Main Types

| Type | Purpose |
|------|---------|
| `XCResult` | Combined build + test results container |
| `BuildResults` / `BuildIssue` | Build warnings, errors, analyzer warnings |
| `TestResults` / `TestNode` / `TestFailure` | Test execution tree and flattened failures |
| `SourceLocation` | Normalized file location with path relativization |
| `TestResult`, `TestNodeType`, `Severity` | Enums with resilient decoding |

## Testing Strategy

- Unit tests with mock JSON fixtures in `Tests/XCResultParserTests/Fixtures/`
- Integration tests with real xcresult bundles (CI environment only)
- Resilient decoding tests for unknown enum values and schema drift
