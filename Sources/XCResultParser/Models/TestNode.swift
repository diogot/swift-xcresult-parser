/// Hierarchical test node from xcresulttool
public struct TestNode: Sendable, Codable, Equatable {
    public let nodeIdentifier: String?
    public let nodeType: TestNodeType
    public let name: String
    public let result: TestResult?
    public let duration: String?
    public let durationInSeconds: Double?
    public let children: [TestNode]?

    public init(
        nodeIdentifier: String? = nil,
        nodeType: TestNodeType,
        name: String,
        result: TestResult? = nil,
        duration: String? = nil,
        durationInSeconds: Double? = nil,
        children: [TestNode]? = nil
    ) {
        self.nodeIdentifier = nodeIdentifier
        self.nodeType = nodeType
        self.name = name
        self.result = result
        self.duration = duration
        self.durationInSeconds = durationInSeconds
        self.children = children
    }
}
