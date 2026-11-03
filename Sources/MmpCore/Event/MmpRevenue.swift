import Foundation

/// 统一收入事件模型。
public struct MmpRevenue: @unchecked Sendable {
    /// 收入数值（如 9.99）。
    public let revenue: Double

    /// ISO 4217 货币代码（如 "USD", "CNY"）。
    public let currency: String

    /// 事件名称。Adjust 模式下需传入后台配置的 event token。
    public let eventName: String

    /// 附加参数。
    public let params: [String: Any]

    public init(
        revenue: Double,
        currency: String,
        eventName: String,
        params: [String: Any] = [:]
    ) {
        self.revenue = revenue
        self.currency = currency
        self.eventName = eventName
        self.params = params
    }
}
