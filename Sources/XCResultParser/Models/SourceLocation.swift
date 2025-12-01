import Foundation

/// Source code location
public struct SourceLocation: Sendable, Equatable {
    /// Original path (absolute for build issues, filename-only for test failures)
    public let file: String

    /// Line number (1-based)
    public let line: Int

    /// Column number (optional, 1-based)
    public let column: Int?

    public init(file: String, line: Int, column: Int? = nil) {
        self.file = file
        self.line = line
        self.column = column
    }

    /// Convert to relative path for annotations
    /// - Parameter repositoryRoot: The repository root directory
    /// - Returns: Path relative to repository root, or original if not under root
    public func relativePath(from repositoryRoot: String) -> String {
        guard file.hasPrefix(repositoryRoot) else {
            return file
        }
        var relative = String(file.dropFirst(repositoryRoot.count))
        if relative.hasPrefix("/") {
            relative = String(relative.dropFirst())
        }
        return relative
    }

    /// Parse sourceURL from build issues
    /// Format: `file:///path/File.swift#EndingColumnNumber=X&EndingLineNumber=X&StartingColumnNumber=X&StartingLineNumber=X&Timestamp=X`
    /// Note: Line numbers in xcresulttool are 0-based, so we add 1 for 1-based output
    public static func fromSourceURL(_ urlString: String) -> SourceLocation? {
        guard urlString.hasPrefix("file://") else { return nil }

        let withoutScheme = String(urlString.dropFirst(7))
        let parts = withoutScheme.split(separator: "#", maxSplits: 1)
        let absolutePath = String(parts[0])

        var line: Int?
        var column: Int?

        // Parse query-string fragment if present
        if parts.count > 1 {
            let fragment = String(parts[1])
            let params = fragment.split(separator: "&")

            for param in params {
                let keyValue = param.split(separator: "=", maxSplits: 1)
                guard keyValue.count == 2 else { continue }

                let key = String(keyValue[0])
                let value = String(keyValue[1])

                switch key {
                case "StartingLineNumber":
                    // xcresulttool uses 0-based line numbers, convert to 1-based
                    if let num = Int(value) {
                        line = num + 1
                    }
                case "StartingColumnNumber":
                    // xcresulttool uses 0-based column numbers, convert to 1-based
                    if let num = Int(value) {
                        column = num + 1
                    }
                default:
                    break
                }
            }
        }

        guard let line else { return nil }

        return SourceLocation(
            file: absolutePath,
            line: line,
            column: column
        )
    }

    /// Parse failure message name from test results
    /// Format: `<filename>:<line>: <message>`
    /// Returns tuple of (location, message)
    public static func fromFailureMessage(_ name: String) -> (location: SourceLocation?, message: String) {
        let pattern = #"^(.+\.swift):(\d+): (.+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)),
              let filenameRange = Range(match.range(at: 1), in: name),
              let lineRange = Range(match.range(at: 2), in: name),
              let messageRange = Range(match.range(at: 3), in: name) else {
            return (nil, name)
        }

        let filename = String(name[filenameRange])
        guard let line = Int(name[lineRange]) else {
            return (nil, name)
        }
        let message = String(name[messageRange])

        return (SourceLocation(file: filename, line: line, column: nil), message)
    }
}
