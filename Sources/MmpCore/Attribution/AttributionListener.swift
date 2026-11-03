import Foundation

/// 归因数据变更回调协议。
public protocol AttributionListener: AnyObject {
    func onAttribution(_ data: AttributionData)
}

/// 闭包适配器
public final class ClosureAttributionListener: AttributionListener {
    private let handler: (AttributionData) -> Void

    public init(handler: @escaping (AttributionData) -> Void) {
        self.handler = handler
    }

    public func onAttribution(_ data: AttributionData) {
        handler(data)
    }
}
