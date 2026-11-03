import Foundation
import MmpCore

#if canImport(AppsFlyerLib)
import AppsFlyerLib
#endif

/// AppsFlyer [MmpClient] 适配器（iOS）。
public final class AppsFlyerClient: NSObject, MmpClient {
    private let lock = NSLock()
    private var attributionListener: AttributionListener?
    private var deepLinkListener: DeepLinkListener?
    private var cachedAttribution: AttributionData?
    private var isInitialized: Bool = false

    private static let logTag = "MmpKit/AppsFlyer"

    public override init() {
        super.init()
    }

    public func initialize(config: MmpConfig) {
        lock.lock()
        defer { lock.unlock() }

        MmpLog.i(
            "AppsFlyer initialize: token=\(MmpLog.maskToken(config.appToken)), " +
            "isDebug=\(config.isDebug), appId=\(config.appId ?? "nil")",
            tag: Self.logTag
        )

        #if canImport(AppsFlyerLib)
        let af = AppsFlyerLib.shared()
        af.appsFlyerDevKey = config.appToken
        af.appleAppID = config.appId ?? ""
        af.isDebug = config.isDebug
        af.delegate = self
        af.deepLinkDelegate = self
        af.start()
        #else
        MmpLog.d("AppsFlyerLib binary not linked; running in adapter mode", tag: Self.logTag)
        #endif

        isInitialized = true
        MmpLog.i("AppsFlyer started", tag: Self.logTag)
    }

    public func setAttributionListener(_ listener: AttributionListener?) {
        lock.lock()
        defer { lock.unlock() }

        MmpLog.d("AppsFlyer setAttributionListener(listener=\(listener != nil))", tag: Self.logTag)
        attributionListener = listener
        if let cached = cachedAttribution {
            MmpLog.d("AppsFlyer delivering cached attribution to new listener: \(cached)", tag: Self.logTag)
            listener?.onAttribution(cached)
        }
    }

    public func setDeepLinkListener(_ listener: DeepLinkListener?) {
        lock.lock()
        defer { lock.unlock() }

        MmpLog.d("AppsFlyer setDeepLinkListener(listener=\(listener != nil))", tag: Self.logTag)
        deepLinkListener = listener
    }

    public func trackEvent(_ event: MmpEvent) {
        lock.lock()
        let initialized = isInitialized
        lock.unlock()

        guard initialized else {
            MmpLog.w("AppsFlyer trackEvent skipped: not initialized", tag: Self.logTag)
            return
        }

        MmpLog.d("AppsFlyer logEvent name=\(event.name), params=\(event.params)", tag: Self.logTag)

        #if canImport(AppsFlyerLib)
        AppsFlyerLib.shared().logEvent(event.name, withValues: event.params)
        #endif
    }

    public func trackRevenue(_ revenue: MmpRevenue) {
        lock.lock()
        let initialized = isInitialized
        lock.unlock()

        guard initialized else {
            MmpLog.w("AppsFlyer trackRevenue skipped: not initialized", tag: Self.logTag)
            return
        }

        var params = revenue.params
        params["af_revenue"] = revenue.revenue
        params["af_currency"] = revenue.currency

        MmpLog.d(
            "AppsFlyer logRevenue name=\(revenue.eventName), " +
            "revenue=\(revenue.revenue), currency=\(revenue.currency), params=\(params)",
            tag: Self.logTag
        )

        #if canImport(AppsFlyerLib)
        AppsFlyerLib.shared().logEvent(revenue.eventName, withValues: params)
        #endif
    }

    public func getAttribution(completion: @escaping (AttributionData?) -> Void) {
        lock.lock()
        let cached = cachedAttribution
        lock.unlock()

        MmpLog.d("AppsFlyer getAttribution cached=\(String(describing: cached))", tag: Self.logTag)
        completion(cached)
    }

    public func peekAttribution() -> AttributionData? {
        lock.lock()
        defer { lock.unlock() }
        return cachedAttribution
    }

    /// 辅助方法：处理转化数据转换
    public func handleConversionData(_ data: [String: Any]) {
        let attribution = Self.mapToAttributionData(data)
        lock.lock()
        cachedAttribution = attribution
        let listener = attributionListener
        lock.unlock()

        MmpLog.i("AppsFlyer attribution: \(attribution)", tag: Self.logTag)
        listener?.onAttribution(attribution)
    }

    /// 辅助方法：处理深度链接回调转换
    public func handleDeepLinkResult(value: String?, clickEvent: [String: Any], isDeferred: Bool) {
        let result = DeepLinkResult(
            deepLinkValue: value,
            clickEvent: clickEvent,
            isDeferred: isDeferred
        )
        lock.lock()
        let listener = deepLinkListener
        lock.unlock()

        MmpLog.i("AppsFlyer deep link: \(result)", tag: Self.logTag)
        listener?.onDeepLink(result)
    }

    private static func mapToAttributionData(_ dict: [String: Any]) -> AttributionData {
        let status = (dict["af_status"] as? String) ?? ""
        let network = dict["media_source"] as? String
        let campaign = dict["campaign"] as? String
        let adGroup = (dict["adgroup"] as? String) ?? (dict["af_adset"] as? String)
        let creative = (dict["af_ad"] as? String) ?? (dict["adgroup"] as? String)
        let clickLabel = dict["af_c_id"] as? String
        let isOrganic = status.caseInsensitiveCompare("Organic") == .orderedSame

        return AttributionData(
            network: network,
            campaign: campaign,
            adGroup: adGroup,
            creative: creative,
            clickLabel: clickLabel,
            isOrganic: isOrganic,
            raw: dict
        )
    }
}

#if canImport(AppsFlyerLib)
extension AppsFlyerClient: AppsFlyerLibDelegate, DeepLinkDelegate {
    public func onConversionDataSuccess(_ conversionInfo: [AnyHashable: Any]) {
        MmpLog.d("AppsFlyer onConversionDataSuccess raw=\(conversionInfo)", tag: Self.logTag)
        var stringKeyedMap: [String: Any] = [:]
        for (k, v) in conversionInfo {
            stringKeyedMap["\(k)"] = v
        }
        handleConversionData(stringKeyedMap)
    }

    public func onConversionDataFail(_ error: Error) {
        MmpLog.w("AppsFlyer onConversionDataFail: \(error.localizedDescription)", tag: Self.logTag)
    }

    public func onAppOpenAttribution(_ attributionData: [AnyHashable: Any]) {
        MmpLog.d("AppsFlyer onAppOpenAttribution (legacy): \(attributionData)", tag: Self.logTag)
    }

    public func onAppOpenAttributionFailure(_ error: Error) {
        MmpLog.w("AppsFlyer onAppOpenAttributionFailure: \(error.localizedDescription)", tag: Self.logTag)
    }

    public func didResolveDeepLink(_ result: AppsFlyerLib.DeepLinkResult) {
        switch result.status {
        case .found:
            guard let dl = result.deepLink else {
                MmpLog.w("AppsFlyer deep link FOUND but payload null", tag: Self.logTag)
                return
            }
            var clickEvent: [String: Any] = [:]
            for (k, v) in dl.clickEvent {
                clickEvent["\(k)"] = v
            }
            handleDeepLinkResult(
                value: dl.deeplinkValue,
                clickEvent: clickEvent,
                isDeferred: dl.isDeferred
            )
        case .notFound:
            MmpLog.d("AppsFlyer deep link not found", tag: Self.logTag)
        case .failure:
            MmpLog.w("AppsFlyer deep link error: \(String(describing: result.error))", tag: Self.logTag)
        @unknown default:
            break
        }
    }
}
#endif
