import Testing
@testable import XCResultParser

@Suite("SourceLocation Tests")
struct SourceLocationTests {
    @Test("Parse source URL with xcresulttool format")
    func parseSourceURLWithXcresulttoolFormat() {
        // Real format from xcresulttool - line numbers are 0-based
        let url = "file:///Users/dev/SampleProject/Sources/ContentView.swift#EndingColumnNumber=30&EndingLineNumber=14&StartingColumnNumber=30&StartingLineNumber=14&Timestamp=786206164.289793"
        let location = SourceLocation.fromSourceURL(url)

        #expect(location != nil)
        #expect(location?.file == "/Users/dev/SampleProject/Sources/ContentView.swift")
        #expect(location?.line == 15) // 0-based 14 becomes 1-based 15
        #expect(location?.column == 31) // 0-based 30 becomes 1-based 31
    }

    @Test("Parse source URL without fragment returns nil")
    func parseSourceURLWithoutFragment() {
        let url = "file:///Users/dev/SampleProject/Sources/ContentView.swift"
        let location = SourceLocation.fromSourceURL(url)

        #expect(location == nil)
    }

    @Test("Parse source URL with minimal fragment")
    func parseSourceURLWithMinimalFragment() {
        let url = "file:///Users/dev/SampleProject/Sources/ContentView.swift#StartingLineNumber=9"
        let location = SourceLocation.fromSourceURL(url)

        #expect(location != nil)
        #expect(location?.file == "/Users/dev/SampleProject/Sources/ContentView.swift")
        #expect(location?.line == 10) // 0-based 9 becomes 1-based 10
        #expect(location?.column == nil)
    }

    @Test("Parse invalid URL returns nil")
    func parseInvalidURL() {
        let location = SourceLocation.fromSourceURL("not-a-file-url")
        #expect(location == nil)
    }

    @Test("Parse source URL with invalid fragment returns nil")
    func parseSourceURLWithInvalidFragment() {
        let url = "file:///Users/dev/SampleProject/Sources/ContentView.swift#InvalidFragment"
        let location = SourceLocation.fromSourceURL(url)

        #expect(location == nil)
    }

    @Test("Parse failure message with location")
    func parseFailureMessageWithLocation() {
        let name = "SampleProjectTests.swift:14: Issue recorded: This test will always fail"
        let (location, message) = SourceLocation.fromFailureMessage(name)

        #expect(location != nil)
        #expect(location?.file == "SampleProjectTests.swift")
        #expect(location?.line == 14)
        #expect(message == "Issue recorded: This test will always fail")
    }

    @Test("Parse failure message without location")
    func parseFailureMessageWithoutLocation() {
        let name = "Some generic error message"
        let (location, message) = SourceLocation.fromFailureMessage(name)

        #expect(location == nil)
        #expect(message == name)
    }

    @Test("Relative path from repository root")
    func relativePath() {
        let location = SourceLocation(
            file: "/Users/dev/SampleProject/Sources/ContentView.swift",
            line: 15
        )

        let relative = location.relativePath(from: "/Users/dev/SampleProject")
        #expect(relative == "Sources/ContentView.swift")
    }

    @Test("Relative path when not under root returns original")
    func relativePathNotUnderRoot() {
        let location = SourceLocation(
            file: "/Other/Path/File.swift",
            line: 10
        )

        let relative = location.relativePath(from: "/Users/dev/SampleProject")
        #expect(relative == "/Other/Path/File.swift")
    }

    @Test("Relative path handles trailing slash")
    func relativePathWithTrailingSlash() {
        let location = SourceLocation(
            file: "/Users/dev/SampleProject/Sources/File.swift",
            line: 1
        )

        let relative = location.relativePath(from: "/Users/dev/SampleProject/")
        #expect(relative == "Sources/File.swift")
    }
}
