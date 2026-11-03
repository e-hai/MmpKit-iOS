import Foundation

/// 深度链接结果回调协议。
public protocol DeepLinkListener: AnyObject {
    func onDeepLink(_ result: DeepLinkResult)
}

/// 闭包适配器
public final class ClosureDeepLinkListener: DeepLinkListener {
    private let handler: (DeepLinkResult) -> Void

    public init(handler: @escaping (DeepLinkResult) -> Void) {
        self.handler = handler
    }

    public func onDeepLink(_ result: DeepLinkResult) {
        handler(result)
    }
}
