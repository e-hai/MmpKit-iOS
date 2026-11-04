import SwiftUI
import MmpCore
import MmpAppsFlyer
import MmpAdjust

@main
struct SampleApp: App {
    static var currentClient: MmpClient?

    init() {
        setupMmp()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    private func setupMmp() {
        // 可从 Info.plist / 环境变量 / 配置文件读取
        let platform = (Bundle.main.infoDictionary?["MMP_PLATFORM"] as? String) ?? "appsflyer"
        let appToken = (Bundle.main.infoDictionary?["MMP_APP_TOKEN"] as? String) ?? "YOUR_DEV_KEY_OR_APP_TOKEN"
        let appId = Bundle.main.infoDictionary?["MMP_APP_ID"] as? String // e.g. "123456789"
        let isDebug = true
        let enableLog = true

        let client: MmpClient
        if platform.caseInsensitiveCompare("adjust") == .orderedSame {
            DemoStore.shared.platformName = "Adjust"
            client = AdjustClient()
        } else {
            DemoStore.shared.platformName = "AppsFlyer"
            client = AppsFlyerClient()
        }

        let config = MmpConfig(
            appToken: appToken,
            isDebug: isDebug,
            appId: appId,
            enableLog: enableLog
        )

        SampleApp.currentClient = client
        Mmp.initialize(config: config, client: client)
        DemoStore.shared.isInitialized = true
        DemoStore.shared.syncFromMmp()

        // 注册归因监听器
        Mmp.setAttributionListener { data in
            DispatchQueue.main.async {
                DemoStore.shared.syncFromMmp()
                DemoStore.shared.appendLog("Attribution arrived: network=\(data.network ?? "nil"), isOrganic=\(data.isOrganic)")
            }
        }

        // 注册深度链接监听器
        Mmp.setDeepLinkListener { result in
            DispatchQueue.main.async {
                DemoStore.shared.latestDeepLink = result
                DemoStore.shared.appendLog("DeepLink received: \(result.deepLinkValue ?? "nil") (deferred=\(result.isDeferred))")
            }
        }
    }
}
