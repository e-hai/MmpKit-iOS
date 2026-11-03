import Foundation

/// 平台 Adapter 核心协议。AppsFlyer / Adjust 等适配器均实现此协议。
public protocol MmpClient: AnyObject {
    /// 初始化适配器
    func initialize(config: MmpConfig)

    /// 注册归因监听器
    func setAttributionListener(_ listener: AttributionListener?)

    /// 注册深度链接监听器
    func setDeepLinkListener(_ listener: DeepLinkListener?)

    /// 上报普通业务事件
    func trackEvent(_ event: MmpEvent)

    /// 上报收入事件
    func trackRevenue(_ revenue: MmpRevenue)

    /// 异步获取归因数据（可能请求平台 SDK 服务端）
    func getAttribution(completion: @escaping (AttributionData?) -> Void)

    /// 立即读取本地缓存的归因数据，若未就绪则返回 nil
    func peekAttribution() -> AttributionData?
}
