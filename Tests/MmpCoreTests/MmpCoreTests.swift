import XCTest
@testable import MmpCore
@testable import MmpAppsFlyer
@testable import MmpAdjust

final class MockClient: MmpClient {
    var initializedConfig: MmpConfig?
    var attributionListener: AttributionListener?
    var deepLinkListener: DeepLinkListener?
    var trackedEvents: [MmpEvent] = []
    var trackedRevenues: [MmpRevenue] = []
    var mockAttribution: AttributionData?
    var openedUrls: [URL] = []
    var continuedActivities: [NSUserActivity] = []

    func initialize(config: MmpConfig) {
        self.initializedConfig = config
    }

    func setAttributionListener(_ listener: AttributionListener?) {
        self.attributionListener = listener
    }

    func setDeepLinkListener(_ listener: DeepLinkListener?) {
        self.deepLinkListener = listener
    }

    func trackEvent(_ event: MmpEvent) {
        trackedEvents.append(event)
    }

    func trackRevenue(_ revenue: MmpRevenue) {
        trackedRevenues.append(revenue)
    }

    func getAttribution(completion: @escaping (AttributionData?) -> Void) {
        completion(mockAttribution)
    }

    func peekAttribution() -> AttributionData? {
        return mockAttribution
    }

    func handleOpenUrl(_ url: URL, options: [AnyHashable: Any]) {
        openedUrls.append(url)
    }

    func continueUserActivity(_ userActivity: NSUserActivity) {
        continuedActivities.append(userActivity)
    }
}

final class MmpCoreTests: XCTestCase {
    func testTokenMasking() {
        XCTAssertEqual(MmpLog.maskToken(nil), "<empty>")
        XCTAssertEqual(MmpLog.maskToken(""), "<empty>")
        XCTAssertEqual(MmpLog.maskToken("1234567"), "****")
        XCTAssertEqual(MmpLog.maskToken("12345678"), "****")
        XCTAssertEqual(MmpLog.maskToken("123456789"), "1234****6789")
        XCTAssertEqual(MmpLog.maskToken("dev_key_secret_token_1234"), "dev_****1234")
    }

    func testLogToggle() {
        Mmp.setLogEnabled(false)
        XCTAssertFalse(Mmp.isLogEnabled())
        Mmp.setLogEnabled(true)
        XCTAssertTrue(Mmp.isLogEnabled())
    }

    func testAttributionDataEquality() {
        let attr1 = AttributionData(
            network: "googleadwords_int",
            campaign: "summer_sale",
            adGroup: "ad_group_1",
            creative: "banner_300x250",
            clickLabel: "click_abc",
            isOrganic: false,
            raw: ["af_status": "Non-organic"]
        )
        let attr2 = AttributionData(
            network: "googleadwords_int",
            campaign: "summer_sale",
            adGroup: "ad_group_1",
            creative: "banner_300x250",
            clickLabel: "click_abc",
            isOrganic: false,
            raw: ["af_status": "Non-organic"]
        )
        XCTAssertEqual(attr1, attr2)
        XCTAssertFalse(attr1.isOrganic)
        XCTAssertEqual(attr1.network, "googleadwords_int")
    }

    func testDeepLinkResultEquality() {
        let dl1 = DeepLinkResult(
            deepLinkValue: "myapp://promo/123",
            clickEvent: ["source": "sms"],
            isDeferred: true
        )
        let dl2 = DeepLinkResult(
            deepLinkValue: "myapp://promo/123",
            clickEvent: ["source": "sms"],
            isDeferred: true
        )
        XCTAssertEqual(dl1, dl2)
        XCTAssertTrue(dl1.isDeferred)
        XCTAssertEqual(dl1.deepLinkValue, "myapp://promo/123")
    }

    func testMmpFacadeLifecycleAndSyncProperties() {
        let mock = MockClient()
        let config = MmpConfig(
            appToken: "test_token_123456789",
            isDebug: true,
            appId: "987654321",
            enableLog: true
        )

        Mmp.initialize(config: config, client: mock)

        XCTAssertEqual(mock.initializedConfig?.appToken, "test_token_123456789")
        XCTAssertTrue(Mmp.isLogEnabled())

        // Cache initially nil
        XCTAssertNil(Mmp.attribution)
        XCTAssertNil(Mmp.isOrganic)
        XCTAssertNil(Mmp.network)

        // Event tracking
        Mmp.trackEvent("test_event", params: ["foo": "bar"])
        XCTAssertEqual(mock.trackedEvents.count, 1)
        XCTAssertEqual(mock.trackedEvents.first?.name, "test_event")

        // Revenue tracking
        Mmp.trackRevenue(MmpRevenue(revenue: 4.99, currency: "USD", eventName: "purchase_token"))
        XCTAssertEqual(mock.trackedRevenues.count, 1)
        XCTAssertEqual(mock.trackedRevenues.first?.revenue, 4.99)
        XCTAssertEqual(mock.trackedRevenues.first?.currency, "USD")

        // Simulate incoming attribution through internal listener
        let testAttr = AttributionData(
            network: "Organic",
            campaign: "organic_campaign",
            adGroup: nil,
            creative: nil,
            clickLabel: nil,
            isOrganic: true
        )
        mock.attributionListener?.onAttribution(testAttr)

        // Verify synchronous facade properties
        XCTAssertEqual(Mmp.attribution, testAttr)
        XCTAssertEqual(Mmp.network, "Organic")
        XCTAssertEqual(Mmp.campaign, "organic_campaign")
        XCTAssertEqual(Mmp.isOrganic, true)

        // Setting a new listener should immediately re-deliver cached attribution
        var receivedByNewListener: AttributionData?
        Mmp.setAttributionListener { data in
            receivedByNewListener = data
        }
        XCTAssertEqual(receivedByNewListener, testAttr)
    }

    func testAppsFlyerAndAdjustAdapters() {
        let afClient = AppsFlyerClient()
        let config = MmpConfig(appToken: "af_token_123456", isDebug: true, appId: "123456")
        afClient.initialize(config: config)
        XCTAssertNil(afClient.peekAttribution())

        afClient.handleConversionData([
            "af_status": "Non-organic",
            "media_source": "bytedance",
            "campaign": "c_game_launch"
        ])

        let afAttr = afClient.peekAttribution()
        XCTAssertNotNil(afAttr)
        XCTAssertEqual(afAttr?.network, "bytedance")
        XCTAssertEqual(afAttr?.campaign, "c_game_launch")
        XCTAssertEqual(afAttr?.isOrganic, false)

        let adjClient = AdjustClient()
        adjClient.initialize(config: config)
        let adjAttr = AdjustClient.mapFromDictionary([
            "network": "facebook",
            "campaign": "retargeting"
        ])
        adjClient.handleAttributionData(adjAttr)
        XCTAssertEqual(adjClient.peekAttribution()?.network, "facebook")
        XCTAssertEqual(adjClient.peekAttribution()?.isOrganic, false)
    }

    func testDirectDeepLinkForwarding() throws {
        let mock = MockClient()
        let config = MmpConfig(appToken: "test_token_123456789", isDebug: true)
        Mmp.initialize(config: config, client: mock)

        let schemeUrl = try XCTUnwrap(URL(string: "mmpkit://promo/spring?coupon=50"))
        Mmp.handleOpenUrl(schemeUrl)
        XCTAssertEqual(mock.openedUrls, [schemeUrl])

        let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
        activity.webpageURL = try XCTUnwrap(URL(string: "https://go.example.com/invite?code=ABC"))
        Mmp.continueUserActivity(activity)
        XCTAssertEqual(mock.continuedActivities.count, 1)
        XCTAssertEqual(mock.continuedActivities.first?.webpageURL, activity.webpageURL)

        let built = AdjustClient.buildDeepLinkResult(url: schemeUrl, isDeferred: false)
        XCTAssertEqual(built.deepLinkValue, "mmpkit://promo/spring?coupon=50")
        XCTAssertEqual(built.clickEvent["coupon"] as? String, "50")
        XCTAssertFalse(built.isDeferred)
    }
}
