import Foundation
import Combine
import MmpCore

public final class DemoStore: ObservableObject {
    public static let shared = DemoStore()

    @Published public var isInitialized: Bool = false
    @Published public var platformName: String = "AppsFlyer"
    @Published public var isLogEnabled: Bool = true

    // Sync cached values
    @Published public var network: String? = nil
    @Published public var campaign: String? = nil
    @Published public var adGroup: String? = nil
    @Published public var creative: String? = nil
    @Published public var clickLabel: String? = nil
    @Published public var isOrganic: Bool? = nil

    @Published public var latestDeepLink: DeepLinkResult? = nil
    @Published public var logs: [String] = []

    private init() {}

    public func syncFromMmp() {
        self.network = Mmp.network
        self.campaign = Mmp.campaign
        self.adGroup = Mmp.adGroup
        self.creative = Mmp.creative
        self.clickLabel = Mmp.clickLabel
        self.isOrganic = Mmp.isOrganic
        self.isLogEnabled = Mmp.isLogEnabled()
    }

    public func appendLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let time = formatter.string(from: Date())
        DispatchQueue.main.async {
            self.logs.insert("[\(time)] \(message)", at: 0)
            if self.logs.count > 100 {
                self.logs.removeLast()
            }
        }
    }
}
