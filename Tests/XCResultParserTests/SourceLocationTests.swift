import Testing
@testable import XCResultParser

@Suite("SourceLocation Tests")
struct SourceLocationTests {
    @Test("Parse source URL with line number")
    func parseSourceURLWithLine() {
        let url = "file:///Users/dev/SampleProject/Sources/ContentView.swift#15"
        let location = SourceLocation.fromSourceURL(url)

        #expect(location != nil)
        #expect(location?.file == "/Users/dev/SampleProject/Sources/ContentView.swift")
        #expect(location?.line == 15)
        #expect(location?.column == nil)
    }

    @Test("Parse source URL without line number defaults to 1")
    func parseSourceURLWithoutLine() {
        let url = "file:///Users/dev/SampleProject/Sources/ContentView.swift"
        let location = SourceLocation.fromSourceURL(url)

        #expect(location != nil)
        #expect(location?.file == "/Users/dev/SampleProject/Sources/ContentView.swift")
        #expect(location?.line == 1)
    }

    @Test("Parse invalid URL returns nil")
    func parseInvalidURL() {
        let location = SourceLocation.fromSourceURL("not-a-file-url")
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
