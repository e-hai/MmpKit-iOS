import Foundation

/// 统一业务事件。
public struct MmpEvent: @unchecked Sendable {
    /// 事件名称。Adjust 模式下需传入后台配置的 event token。
    public let name: String

    /// 自定义参数键值对。
    public let params: [String: Any]

    public init(name: String, params: [String: Any] = [:]) {
        self.name = name
        self.params = params
    }
}
