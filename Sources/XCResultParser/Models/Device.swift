/// Device information from test results
public struct Device: Sendable, Codable, Equatable {
    public let architecture: String?
    public let deviceId: String?
    public let deviceName: String?
    public let modelName: String?
    public let osBuildNumber: String?
    public let osVersion: String?
    public let platform: String?

    public init(
        architecture: String? = nil,
        deviceId: String? = nil,
        deviceName: String? = nil,
        modelName: String? = nil,
        osBuildNumber: String? = nil,
        osVersion: String? = nil,
        platform: String? = nil
    ) {
        self.architecture = architecture
        self.deviceId = deviceId
        self.deviceName = deviceName
        self.modelName = modelName
        self.osBuildNumber = osBuildNumber
        self.osVersion = osVersion
        self.platform = platform
    }
}
