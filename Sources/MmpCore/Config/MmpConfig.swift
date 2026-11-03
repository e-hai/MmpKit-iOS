import Foundation

/// 统一 MMP 配置。
///
/// `appToken` 映射为 AppsFlyer devKey 或 Adjust appToken。
/// 平台专属配置由各 Adapter 的初始化入参提供，不污染通用模型。
public struct MmpConfig: Sendable {
    /// 平台鉴权令牌（AppsFlyer devKey / Adjust appToken）。
    public let appToken: String

    /// 是否开启平台 SDK 自身 debug；Adjust 下对应 Sandbox 环境。
    public let isDebug: Bool

    /// 应用标识（iOS 下对应 App Store ID，如 "123456789"，AppsFlyer 必需）。
    public let appId: String?

    /// 是否开启 MmpKit 内部详细日志（与平台 SDK 自身 debug 独立）。
    public let enableLog: Bool

    public init(
        appToken: String,
        isDebug: Bool = false,
        appId: String? = nil,
        enableLog: Bool = false
    ) {
        self.appToken = appToken
        self.isDebug = isDebug
        self.appId = appId
        self.enableLog = enableLog
    }
}
