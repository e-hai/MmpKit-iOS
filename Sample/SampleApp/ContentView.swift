import SwiftUI
import MmpCore
import MmpAppsFlyer
import MmpAdjust

public struct ContentView: View {
    @ObservedObject var store = DemoStore.shared

    public init() {}

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Status
                    statusCard

                    // Attribution Cache Card
                    attributionCard

                    // Action Buttons Card
                    actionsCard

                    // Mock Simulation Card
                    simulationCard

                    // Log Console Card
                    logsCard
                }
                .padding()
            }
            .navigationTitle("MmpKit iOS Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("平台状态")
                    .font(.headline)
                Spacer()
                Text(store.platformName)
                    .font(.subheadline)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }
            Divider()
            HStack {
                Text("Mmp 日志:")
                Spacer()
                Text(store.isLogEnabled ? "开启" : "关闭")
                    .foregroundColor(store.isLogEnabled ? .green : .gray)
            }
            HStack {
                Text("自然量状态 (isOrganic):")
                Spacer()
                if let isOrganic = store.isOrganic {
                    Text(isOrganic ? "True (自然量)" : "False (买量)")
                        .foregroundColor(isOrganic ? .orange : .purple)
                } else {
                    Text("未就绪 (nil)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var attributionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("同步读取归因缓存 (Mmp.*)")
                .font(.headline)
            Divider()
            attributionRow("network", value: store.network)
            attributionRow("campaign", value: store.campaign)
            attributionRow("adGroup", value: store.adGroup)
            attributionRow("creative", value: store.creative)
            attributionRow("clickLabel", value: store.clickLabel)

            if let dl = store.latestDeepLink {
                Divider()
                Text("深度链接 (DeepLink):")
                    .font(.subheadline)
                    .bold()
                Text("Value: \(dl.deepLinkValue ?? "nil") (isDeferred=\(dl.isDeferred))")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func attributionRow(_ title: String, value: String?) -> some View {
        HStack {
            Text("\(title):")
                .foregroundColor(.secondary)
            Spacer()
            Text(value ?? "nil")
                .bold()
        }
        .font(.footnote)
    }

    private var actionsCard: some View {
        VStack(spacing: 12) {
            Button(action: trackCustomEvent) {
                HStack {
                    Image(systemName: "flag.fill")
                    Text("上报业务事件 (level_complete)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            Button(action: trackRevenueEvent) {
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                    Text("上报收入事件 ($9.99 USD)")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }

            HStack(spacing: 12) {
                Button(action: refreshAttributionAsync) {
                    Text("异步查询归因")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }

                Button(action: toggleLogs) {
                    Text(store.isLogEnabled ? "关闭日志" : "开启日志")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
        }
    }

    private var simulationCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("本地模拟测试 (Mock Simulation)")
                .font(.headline)
            Text("无需白名单真机或线上配置，可直接模拟买量与深度链接")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack(spacing: 10) {
                Button(action: simulateNonOrganic) {
                    Text("模拟买量归因")
                        .font(.footnote)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }

                Button(action: simulateOrganic) {
                    Text("模拟自然量")
                        .font(.footnote)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.teal)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }

            Button(action: simulateDeepLink) {
                HStack {
                    Image(systemName: "link")
                    Text("模拟深度链接 (myapp://promo/spring_sale)")
                        .font(.footnote)
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.indigo.opacity(0.85))
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    private var logsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Activity Logs")
                    .font(.headline)
                Spacer()
                Button("清空") {
                    store.logs.removeAll()
                }
                .font(.footnote)
            }
            Divider()
            if store.logs.isEmpty {
                Text("暂无日志")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(store.logs, id: \.self) { log in
                    Text(log)
                        .font(.system(size: 11, design: .monospaced))
                        .padding(.vertical, 1)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    // Actions
    private func trackCustomEvent() {
        Mmp.trackEvent("level_complete", params: ["level": 3, "difficulty": "hard"])
        store.appendLog("TrackEvent: level_complete (level=3)")
    }

    private func trackRevenueEvent() {
        let rev = MmpRevenue(
            revenue: 9.99,
            currency: "USD",
            eventName: "purchase",
            params: ["sku": "coin_pack_s"]
        )
        Mmp.trackRevenue(rev)
        store.appendLog("TrackRevenue: $9.99 USD for purchase")
    }

    private func refreshAttributionAsync() {
        store.appendLog("Requesting Mmp.getAttribution()...")
        Mmp.getAttribution { data in
            DispatchQueue.main.async {
                store.syncFromMmp()
                if let data = data {
                    store.appendLog("getAttribution callback: network=\(data.network ?? "nil"), organic=\(data.isOrganic)")
                } else {
                    store.appendLog("getAttribution callback: nil")
                }
            }
        }
    }

    private func toggleLogs() {
        let current = Mmp.isLogEnabled()
        Mmp.setLogEnabled(!current)
        store.syncFromMmp()
        store.appendLog("Mmp.setLogEnabled(\(!current))")
    }

    private func simulateNonOrganic() {
        if let af = SampleApp.currentClient as? AppsFlyerClient {
            af.simulateConversionData([
                "af_status": "Non-organic",
                "media_source": "googleadwords_int",
                "campaign": "summer_sale_2026",
                "af_adset": "group_ios",
                "af_ad": "banner_300x250",
            ])
        } else if let adj = SampleApp.currentClient as? AdjustClient {
            adj.simulateAttributionData(
                AttributionData(
                    network: "googleadwords_int",
                    campaign: "summer_sale_2026",
                    adGroup: "group_ios",
                    creative: "banner_300x250",
                    clickLabel: nil,
                    isOrganic: false
                )
            )
        }
        store.syncFromMmp()
        store.appendLog("Simulated: Non-organic attribution injected")
    }

    private func simulateOrganic() {
        if let af = SampleApp.currentClient as? AppsFlyerClient {
            af.simulateConversionData([
                "af_status": "Organic",
            ])
        } else if let adj = SampleApp.currentClient as? AdjustClient {
            adj.simulateAttributionData(
                AttributionData(
                    network: "Organic",
                    campaign: nil,
                    adGroup: nil,
                    creative: nil,
                    clickLabel: nil,
                    isOrganic: true
                )
            )
        }
        store.syncFromMmp()
        store.appendLog("Simulated: Organic attribution injected")
    }

    private func simulateDeepLink() {
        if let af = SampleApp.currentClient as? AppsFlyerClient {
            af.simulateDeepLink(
                value: "myapp://promo/spring_sale",
                clickEvent: ["campaign": "spring_sale", "discount": "50%"],
                isDeferred: true
            )
        } else if let adj = SampleApp.currentClient as? AdjustClient {
            adj.simulateDeepLink(
                value: "myapp://promo/spring_sale",
                clickEvent: ["campaign": "spring_sale", "discount": "50%"],
                isDeferred: true
            )
        }
        store.appendLog("Simulated: DeepLink event injected")
    }
}
