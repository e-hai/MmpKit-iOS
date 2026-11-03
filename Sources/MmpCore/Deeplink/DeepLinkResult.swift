import Foundation

/// 深度链接与延迟深度链接结果。
public struct DeepLinkResult: Equatable, @unchecked Sendable {
    public let deepLinkValue: String?
    public let clickEvent: [String: Any]
    public let isDeferred: Bool

    public init(
        deepLinkValue: String? = nil,
        clickEvent: [String: Any] = [:],
        isDeferred: Bool = false
    ) {
        self.deepLinkValue = deepLinkValue
        self.clickEvent = clickEvent
        self.isDeferred = isDeferred
    }

    public static func == (lhs: DeepLinkResult, rhs: DeepLinkResult) -> Bool {
        return lhs.deepLinkValue == rhs.deepLinkValue &&
            lhs.isDeferred == rhs.isDeferred &&
            NSDictionary(dictionary: lhs.clickEvent).isEqual(to: rhs.clickEvent)
    }
}
