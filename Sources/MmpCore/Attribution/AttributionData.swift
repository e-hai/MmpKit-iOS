import Foundation

/// 跨平台归一化后的归因结果。
///
/// 由各 MMP Adapter（AppsFlyer / Adjust 等）从平台原始回调映射而来，
/// 业务侧优先使用统一字段；需要平台特有字段时再查 [raw]。
///
/// 字段对应关系（常见）：
/// - AppsFlyer：`media_source` → [network]，`campaign` → [campaign]，
///   `adgroup` / `af_adset` → [adGroup]，`af_ad` → [creative]，
///   `af_status == Organic` → [isOrganic]
/// - Adjust：`network` / `campaign` / `adgroup` / `creative` / `clickLabel` 同名映射
public struct AttributionData: Equatable, @unchecked Sendable {
    /// 媒体渠道 / 广告网络，如 `Facebook Ads`、`googleadwords_int`；自然量为 nil 或由 [isOrganic] 标识。
    public let network: String?

    /// 广告活动（Campaign）名称。
    public let campaign: String?

    /// 广告组（Ad Group / Ad Set）名称。
    public let adGroup: String?

    /// 创意（Creative / Ad）名称。
    public let creative: String?

    /// 点击标签（Click Label）；部分平台用于自定义点击标识，无则 nil。
    public let clickLabel: String?

    /// 是否为自然量安装（Organic）。`true` 表示未归因到付费/合作渠道。
    public let isOrganic: Bool

    /// 平台原始字段兜底。
    /// 保留未归一化的键值，便于排查或读取统一模型未覆盖的字段。
    public let raw: [String: Any]

    public init(
        network: String? = nil,
        campaign: String? = nil,
        adGroup: String? = nil,
        creative: String? = nil,
        clickLabel: String? = nil,
        isOrganic: Bool = false,
        raw: [String: Any] = [:]
    ) {
        self.network = network
        self.campaign = campaign
        self.adGroup = adGroup
        self.creative = creative
        self.clickLabel = clickLabel
        self.isOrganic = isOrganic
        self.raw = raw
    }

    public static func == (lhs: AttributionData, rhs: AttributionData) -> Bool {
        return lhs.network == rhs.network &&
            lhs.campaign == rhs.campaign &&
            lhs.adGroup == rhs.adGroup &&
            lhs.creative == rhs.creative &&
            lhs.clickLabel == rhs.clickLabel &&
            lhs.isOrganic == rhs.isOrganic &&
            NSDictionary(dictionary: lhs.raw).isEqual(to: rhs.raw)
    }
}
