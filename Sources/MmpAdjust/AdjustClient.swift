import Foundation
import MmpCore

#if canImport(AdjustSdk)
import AdjustSdk
#elseif canImport(Adjust)
import Adjust
#endif

/// Adjust [MmpClient] 适配器（iOS）。
///
/// 注意：[MmpEvent.name] / [MmpRevenue.eventName] 对应 Adjust 后台的 **event token**。
public final class AdjustClient: NSObject, MmpClient {
    private let lock = NSLock()
    private var attributionListener: AttributionListener?
    private var deepLinkListener: DeepLinkListener?
    private var cachedAttribution: AttributionData?
    private var isInitialized: Bool = false

    private static let logTag = "MmpKit/Adjust"

    public override init() {
        super.init()
    }

    public func initialize(config: MmpConfig) {
        lock.lock()
        defer { lock.unlock() }

        let envString = config.isDebug ? "sandbox" : "production"
        MmpLog.i(
            "Adjust initialize: token=\(MmpLog.maskToken(config.appToken)), " +
            "env=\(envString), isDebug=\(config.isDebug), appId=\(config.appId ?? "nil")",
            tag: Self.logTag
        )

        #if canImport(AdjustSdk) || canImport(Adjust)
        let environment = config.isDebug ? ADJEnvironmentSandbox : ADJEnvironmentProduction
        if let adjConfig = ADJConfig(appToken: config.appToken, environment: environment) {
            adjConfig.logLevel = config.isDebug ? ADJLogLevelVerbose : ADJLogLevelWarn
            adjConfig.delegate = self
            Adjust.initSdk(adjConfig)
        }
        #else
        MmpLog.d("Adjust SDK binary not linked; running in adapter mode", tag: Self.logTag)
        #endif

        isInitialized = true
        MmpLog.i("Adjust SDK initialized", tag: Self.logTag)
    }

    public func setAttributionListener(_ listener: AttributionListener?) {
        lock.lock()
        defer { lock.unlock() }

        MmpLog.d("Adjust setAttributionListener(listener=\(listener != nil))", tag: Self.logTag)
        attributionListener = listener
        if let cached = cachedAttribution {
            MmpLog.d("Adjust delivering cached attribution to new listener: \(cached)", tag: Self.logTag)
            listener?.onAttribution(cached)
        }
    }

    public func setDeepLinkListener(_ listener: DeepLinkListener?) {
        lock.lock()
        defer { lock.unlock() }

        MmpLog.d("Adjust setDeepLinkListener(listener=\(listener != nil))", tag: Self.logTag)
        deepLinkListener = listener
    }

    public func trackEvent(_ event: MmpEvent) {
        MmpLog.d("Adjust trackEvent token=\(event.name), params=\(event.params)", tag: Self.logTag)

        #if canImport(AdjustSdk) || canImport(Adjust)
        if let adjEvent = ADJEvent(eventToken: event.name) {
            for (key, value) in event.params {
                adjEvent.addCallbackParameter(key, value: "\(value)")
            }
            Adjust.trackEvent(adjEvent)
        }
        #endif
    }

    public func trackRevenue(_ revenue: MmpRevenue) {
        MmpLog.d(
            "Adjust trackRevenue token=\(revenue.eventName), revenue=\(revenue.revenue), " +
            "currency=\(revenue.currency), params=\(revenue.params)",
            tag: Self.logTag
        )

        #if canImport(AdjustSdk) || canImport(Adjust)
        if let adjEvent = ADJEvent(eventToken: revenue.eventName) {
            adjEvent.setRevenue(revenue.revenue, currency: revenue.currency)
            for (key, value) in revenue.params {
                adjEvent.addCallbackParameter(key, value: "\(value)")
            }
            Adjust.trackEvent(adjEvent)
        }
        #endif
    }

    public func getAttribution(completion: @escaping (AttributionData?) -> Void) {
        lock.lock()
        if let cached = cachedAttribution {
            lock.unlock()
            MmpLog.d("Adjust getAttribution from cache: \(cached)", tag: Self.logTag)
            completion(cached)
            return
        }
        lock.unlock()

        MmpLog.d("Adjust getAttribution fetching from SDK", tag: Self.logTag)

        #if canImport(AdjustSdk) || canImport(Adjust)
        Adjust.attribution { [weak self] attribution in
            guard let self = self else { return }
            let data = attribution.map { Self.mapToAttributionData($0) }
            if let data = data {
                self.lock.lock()
                self.cachedAttribution = data
                self.lock.unlock()
            }
            MmpLog.d("Adjust getAttribution result=\(String(describing: data))", tag: Self.logTag)
            completion(data)
        }
        #else
        completion(nil)
        #endif
    }

    public func peekAttribution() -> AttributionData? {
        lock.lock()
        defer { lock.unlock() }
        return cachedAttribution
    }

    /// 本地测试 / 模拟方法：手动注入归因数据，无需连接 Adjust 真实后台。
    public func simulateAttributionData(_ data: AttributionData) {
        handleAttributionData(data)
    }

    /// 本地测试 / 模拟方法：手动触发深度链接回调。
    public func simulateDeepLink(value: String?, clickEvent: [String: Any] = [:], isDeferred: Bool = false) {
        handleDeepLinkResult(DeepLinkResult(deepLinkValue: value, clickEvent: clickEvent, isDeferred: isDeferred))
    }

    /// 辅助方法：分发归因数据并更新本地缓存
    public func handleAttributionData(_ attribution: AttributionData) {
        lock.lock()
        cachedAttribution = attribution
        let listener = attributionListener
        lock.unlock()

        MmpLog.i("Adjust onAttributionChanged: \(attribution)", tag: Self.logTag)
        listener?.onAttribution(attribution)
    }

    /// 辅助方法：分发深度链接数据
    public func handleDeepLinkResult(_ result: DeepLinkResult) {
        lock.lock()
        let listener = deepLinkListener
        lock.unlock()

        MmpLog.i("Adjust deferred deeplink: \(result)", tag: Self.logTag)
        listener?.onDeepLink(result)
    }

    /// 字典转换归因数据辅助方法
    public static func mapFromDictionary(_ dict: [String: Any]) -> AttributionData {
        let network = dict["network"] as? String
        let isOrganic = network == nil ||
            network?.isEmpty == true ||
            network?.caseInsensitiveCompare("Organic") == .orderedSame

        return AttributionData(
            network: network,
            campaign: dict["campaign"] as? String,
            adGroup: dict["adgroup"] as? String,
            creative: dict["creative"] as? String,
            clickLabel: dict["clickLabel"] as? String,
            isOrganic: isOrganic,
            raw: dict
        )
    }
}

#if canImport(AdjustSdk) || canImport(Adjust)
extension AdjustClient: AdjustDelegate {
    public func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        guard let attribution = attribution else { return }
        let data = Self.mapToAttributionData(attribution)
        handleAttributionData(data)
    }

    public func adjustDeeplinkResponse(_ deeplink: URL?) -> Bool {
        guard let uri = deeplink else {
            MmpLog.d("Adjust deferred deeplink nil", tag: Self.logTag)
            return false
        }

        var queryParams: [String: Any] = [:]
        if let components = URLComponents(url: uri, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            for item in queryItems {
                queryParams[item.name] = item.value ?? ""
            }
        }

        let result = DeepLinkResult(
            deepLinkValue: uri.absoluteString,
            clickEvent: queryParams,
            isDeferred: true
        )
        handleDeepLinkResult(result)
        return false
    }

    private static func mapToAttributionData(_ attr: ADJAttribution) -> AttributionData {
        var raw: [String: Any] = [:]
        raw["trackerToken"] = attr.trackerToken
        raw["trackerName"] = attr.trackerName
        raw["network"] = attr.network
        raw["campaign"] = attr.campaign
        raw["adgroup"] = attr.adgroup
        raw["creative"] = attr.creative
        raw["clickLabel"] = attr.clickLabel
        raw["costType"] = attr.costType
        raw["costAmount"] = attr.costAmount
        raw["costCurrency"] = attr.costCurrency

        let isOrganic = attr.network == nil ||
            attr.network?.isEmpty == true ||
            attr.network?.caseInsensitiveCompare("Organic") == .orderedSame

        return AttributionData(
            network: attr.network,
            campaign: attr.campaign,
            adGroup: attr.adgroup,
            creative: attr.creative,
            clickLabel: attr.clickLabel,
            isOrganic: isOrganic,
            raw: raw
        )
    }
}
#endif
