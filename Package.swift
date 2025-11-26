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
        .testTarget(
            name: "XCResultParserTests",
            dependencies: ["XCResultParser"],
            resources: [.copy("Fixtures")]
        )
    ]
)
