import Foundation

/// MMP 跨平台统一门面（Facade）。
///
/// 业务侧统一通过 `Mmp` 静态方法调用，在初始化前调用方法均为空操作（带警告日志）。
/// 归因数据在首次成功获取或平台回调后自动缓存在内存中。
/// 常见业务判断优先使用同步属性（`attribution`, `isOrganic`, `network`, ...）；
/// 如需第一时间响应平台回调，请设置 `setAttributionListener`。
public final class Mmp {
    public static let shared = Mmp()
    private init() {}

    private let lock = NSRecursiveLock()
    private var client: MmpClient?
    private var cachedAttribution: AttributionData?
    private var userAttributionListener: AttributionListener?
    private var userClosureListener: ClosureAttributionListener?

    /// 最新缓存的归因结果，若尚未就绪则返回 nil。
    public static var attribution: AttributionData? {
        return shared.getAttributionProperty()
    }

    /// 媒体渠道；归因未就绪时为 nil。
    public static var network: String? {
        return attribution?.network
    }

    /// 广告活动；归因未就绪时为 nil。
    public static var campaign: String? {
        return attribution?.campaign
    }

    /// 广告组；归因未就绪时为 nil。
    public static var adGroup: String? {
        return attribution?.adGroup
    }

    /// 创意；归因未就绪时为 nil。
    public static var creative: String? {
        return attribution?.creative
    }

    /// 点击标签；归因未就绪时为 nil。
    public static var clickLabel: String? {
        return attribution?.clickLabel
    }

    /// 是否为自然量。
    /// - `true` / `false`：已有归因结果
    /// - `nil`：归因尚未就绪
    public static var isOrganic: Bool? {
        return attribution?.isOrganic
    }

    /// 运行时日志开关。`init` 时也会根据 `MmpConfig.enableLog` 自动配置。
    public static func setLogEnabled(_ enabled: Bool) {
        MmpLog.enabled = enabled
        MmpLog.i("setLogEnabled(\(enabled))")
    }

    public static func isLogEnabled() -> Bool {
        return MmpLog.enabled
    }

    /// 初始化统一门面与底层 Adapter。
    public static func initialize(config: MmpConfig, client: MmpClient) {
        shared.lock.lock()
        defer { shared.lock.unlock() }

        MmpLog.enabled = config.enableLog
        MmpLog.i(
            "init start: client=\(type(of: client)), " +
            "token=\(MmpLog.maskToken(config.appToken)), " +
            "isDebug=\(config.isDebug), appId=\(config.appId ?? "nil"), enableLog=\(config.enableLog)"
        )
        shared.cachedAttribution = nil
        shared.client = client
        client.initialize(config: config)

        // 绑定内部监听器以保证门面缓存始终最新，即使业务层未显式注册监听器
        client.setAttributionListener(shared.internalAttributionListener)
        MmpLog.i("init done")
    }

    /// 设置归因监听器（协议形式）。
    /// 若此时已有缓存，会立即向新监听器补发一次。
    public static func setAttributionListener(_ listener: AttributionListener?) {
        shared.lock.lock()
        defer { shared.lock.unlock() }

        MmpLog.d("setAttributionListener(listener=\(listener != nil))")
        shared.userAttributionListener = listener
        shared.userClosureListener = nil

        if let current = shared.cachedAttribution ?? shared.client?.peekAttribution() {
            shared.cachedAttribution = current
            listener?.onAttribution(current)
        }
    }

    /// 设置归因监听器（闭包形式）。
    public static func setAttributionListener(_ handler: @escaping (AttributionData) -> Void) {
        let listener = ClosureAttributionListener(handler: handler)
        shared.lock.lock()
        shared.userClosureListener = listener
        shared.lock.unlock()
        setAttributionListener(listener)
    }

    /// 设置深度链接监听器（协议形式）。
    public static func setDeepLinkListener(_ listener: DeepLinkListener?) {
        MmpLog.d("setDeepLinkListener(listener=\(listener != nil))")
        shared.withClient("setDeepLinkListener") { client in
            client.setDeepLinkListener(listener)
        }
    }

    /// 设置深度链接监听器（闭包形式）。
    public static func setDeepLinkListener(_ handler: @escaping (DeepLinkResult) -> Void) {
        let listener = ClosureDeepLinkListener(handler: handler)
        setDeepLinkListener(listener)
    }

    /// 上报普通业务事件（快捷方法）。
    public static func trackEvent(_ name: String, params: [String: Any] = [:]) {
        trackEvent(MmpEvent(name: name, params: params))
    }

    /// 上报完整业务事件。
    public static func trackEvent(_ event: MmpEvent) {
        MmpLog.d("trackEvent(name=\(event.name), params=\(event.params))")
        shared.withClient("trackEvent") { client in
            client.trackEvent(event)
        }
    }

    /// 上报收入事件。
    public static func trackRevenue(_ revenue: MmpRevenue) {
        MmpLog.d(
            "trackRevenue(name=\(revenue.eventName), revenue=\(revenue.revenue), " +
            "currency=\(revenue.currency), params=\(revenue.params))"
        )
        shared.withClient("trackRevenue") { client in
            client.trackRevenue(revenue)
        }
    }

    /// 异步获取归因数据（可能触发平台网络请求），并刷新本地缓存。
    public static func getAttribution(completion: @escaping (AttributionData?) -> Void) {
        MmpLog.d("getAttribution()")
        let currentClient: MmpClient?
        shared.lock.lock()
        currentClient = shared.client
        shared.lock.unlock()

        guard let client = currentClient else {
            MmpLog.w("getAttribution called before init; returning nil")
            completion(nil)
            return
        }

        client.getAttribution { data in
            if let data = data {
                shared.lock.lock()
                shared.cachedAttribution = data
                shared.lock.unlock()
            }
            MmpLog.d("getAttribution result=\(String(describing: data))")
            completion(data)
        }
    }

    private func getAttributionProperty() -> AttributionData? {
        lock.lock()
        defer { lock.unlock() }
        if let cached = cachedAttribution {
            return cached
        }
        if let peeked = client?.peekAttribution() {
            cachedAttribution = peeked
            return peeked
        }
        return nil
    }

    private lazy var internalAttributionListener: AttributionListener = {
        ClosureAttributionListener { [weak self] data in
            guard let self = self else { return }
            self.lock.lock()
            self.cachedAttribution = data
            let listener = self.userAttributionListener
            self.lock.unlock()

            MmpLog.d("attribution cached: network=\(data.network ?? "nil"), campaign=\(data.campaign ?? "nil"), organic=\(data.isOrganic)")
            listener?.onAttribution(data)
        }
    }()

    private func withClient(_ action: String, block: (MmpClient) -> Void) {
        lock.lock()
        let current = client
        lock.unlock()

        guard let client = current else {
            MmpLog.w("\(action) called before init; no-op")
            return
        }
        block(client)
    }
}
