# AGENTS.md — guidance for coding agents (iOS)

This file is for AI agents working in **MmpKit (iOS branch)**. Prefer it over guessing. Human integration docs: `README.md`.

## What this repo is

iOS library that wraps MMP attribution SDKs (AppsFlyer, Adjust, …) behind one Swift facade (`Mmp`) so iOS apps switch vendors by swapping the `MmpClient` implementation—not by changing call sites.

## Module & Target map

| Target / Subspec | Namespace / Module | Role |
|------------------|--------------------|------|
| `MmpCore` | `MmpCore` | Public API: `Mmp`, `MmpClient`, models, `MmpLog`. **No** vendor SDKs. |
| `MmpAppsFlyer` | `MmpAppsFlyer` | `AppsFlyerClient` → AppsFlyer iOS SDK (`AppsFlyerLib`) |
| `MmpAdjust` | `MmpAdjust` | `AdjustClient` → Adjust iOS SDK (`AdjustSdk` / `Adjust`) |
| `SampleApp` | `SampleApp` | Demo app (SwiftUI). Interacts with facade only. |

- Package Manager: Swift Package Manager (`Package.swift`) & CocoaPods (`MmpKit.podspec`)
- Min deployment target: iOS 13.0, macOS 10.15
- Swift version: Swift 5.9+ / Swift 6 compatible

## Package layout (`Sources/MmpCore`)

```
Sources/MmpCore/
  Mmp.swift, MmpClient.swift
  Config/MmpConfig.swift
  Log/MmpLog.swift
  Event/MmpEvent.swift, MmpRevenue.swift
  Attribution/AttributionData.swift, AttributionListener.swift
  Deeplink/DeepLinkResult.swift, DeepLinkListener.swift
```

## Architecture rules (do not violate)

1. **Business → facade only.** Call sites use `Mmp.*`. Vendor details stay inside adapters.
2. **`MmpConfig` stays vendor-neutral.** Platform-only options go on adapter constructors / `*Options` in that module—not in `MmpCore`. Note: `appId` in `MmpConfig` is the Apple App ID required by AppsFlyer on iOS.
3. **Cross-platform capability** → keep alignment with Android branch API and normalized data models.
4. **Out of scope for core** (unless product explicitly asks): customer user id, uninstall, push token, ATT/GDPR consent dialogs, IDFA raw collection.
5. **Logging:** only via `MmpLog`, gated by `MmpConfig.enableLog` / `Mmp.setLogEnabled(_:)`. Never log raw tokens—use `MmpLog.maskToken(_:)`. `isDebug` controls **vendor** SDK debug/sandbox only.
6. **Attribution cache:** `Mmp` caches results and exposes sync getters. Adapters must implement `peekAttribution()`. On `initialize`, facade registers an internal attribution listener to keep cache warm even if the app never sets one.
7. **Thread Safety:** `Mmp` uses thread synchronization (`NSRecursiveLock`) to guard cache and listener delivery.

## Public API surface (`Mmp`)

| API | Notes |
|-----|--------|
| `initialize(config, client)` | Clears attribution cache; wires internal listener |
| `setLogEnabled` / `isLogEnabled` | Runtime log switch |
| `trackEvent` / `trackRevenue` | No-op + warn before init |
| `attribution`, `network`, `campaign`, `adGroup`, `creative`, `clickLabel`, `isOrganic` | Sync cache; `nil` = not ready |
| `setAttributionListener` | Forwards after cache update; re-delivers cache immediately if present |
| `getAttribution { }` | Async; may hit vendor SDK; refreshes cache |
| `setDeepLinkListener` | Deep link / deferred deep link |

`MmpClient` must implement: `initialize`, `setAttributionListener`, `setDeepLinkListener`, `trackEvent`, `trackRevenue`, `getAttribution`, `peekAttribution`.

## Vendor quirks (iOS)

**AppsFlyer**
- `appToken` = Dev Key
- `appId` = Apple App ID (e.g. `123456789`)
- Event names are readable strings
- Revenue: `af_revenue` + `af_currency`
- Deep link: `DeepLinkDelegate` (`didResolveDeepLink`)
- SKAdNetwork / ATT handling stays in app or specialized module

**Adjust**
- `appToken` = App Token
- `MmpEvent.name` / `MmpRevenue.eventName` = **event tokens**
- `isDebug` → sandbox vs production
- Deferred deep links: `adjustDeeplinkResponse` delegate

## Build / verify

```bash
swift build
swift test
```
