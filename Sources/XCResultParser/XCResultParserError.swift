import Foundation

/// Errors that can occur during xcresult parsing
public enum XCResultParserError: Error, LocalizedError, Equatable {
    case bundleNotFound(String)
    case xcresulttoolNotFound
    case xcresulttoolFailed(String)
    case invalidJSON(String)
    case noBuildResults
    case noTestResults

    public var errorDescription: String? {
        switch self {
        case .bundleNotFound(let path):
            "xcresult bundle not found at path: \(path)"
        case .xcresulttoolNotFound:
            "xcrun xcresulttool not found. Ensure Xcode Command Line Tools are installed."
        case .xcresulttoolFailed(let message):
            "xcresulttool failed: \(message)"
        case .invalidJSON(let message):
            "Failed to parse JSON response: \(message)"
        case .noBuildResults:
            "No build results found in xcresult bundle"
        case .noTestResults:
            "No test results found in xcresult bundle"
        }
    }
}
