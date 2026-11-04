# AGENTS.md — Guidance for Coding Agents (MmpKit-iOS)

This file is for AI agents (Codex, Claude, Copilot, etc.) working in **MmpKit-iOS**. Prefer it over guessing. Human integration docs: `README.md`.

## What this repo is

iOS library that wraps MMP attribution SDKs (AppsFlyer, Adjust, …) behind one unified Swift facade (`Mmp`) so iOS apps switch vendors by swapping the `MmpClient` implementation—not by changing business call sites.

## Module & Target Map

| Target / Subspec | Namespace / Module | Role |
|------------------|--------------------|------|
| `MmpCore` | `MmpCore` | Public API: `Mmp`, `MmpClient`, models, `MmpLog`. **Zero** vendor SDK dependencies. |
| `MmpAppsFlyer` | `MmpAppsFlyer` | `AppsFlyerClient` → AppsFlyer iOS SDK (`AppsFlyerLib`) |
| `MmpAdjust` | `MmpAdjust` | `AdjustClient` → Adjust iOS SDK (`AdjustSdk` / `Adjust`) |
| `MmpKitDemo` | `MmpKitDemo` | Demo app (SwiftUI). Interacts with facade only. Generated via XcodeGen (`project.yml`). |

- Package Managers: Swift Package Manager (`Package.swift`) & CocoaPods (`MmpKit.podspec`)
- Min deployment target: iOS 13.0, macOS 10.15
- Swift version: Swift 5.9+ / Swift 6 compatible
- Coordinates: `https://github.com/e-hai/MmpKit-iOS.git` (tag: `1.0.0`)

## Package Layout (`Sources/MmpCore`)

```
Sources/MmpCore/
  Mmp.swift, MmpClient.swift
  Config/MmpConfig.swift
  Log/MmpLog.swift
  Event/MmpEvent.swift, MmpRevenue.swift
  Attribution/AttributionData.swift, AttributionListener.swift
  Deeplink/DeepLinkResult.swift, DeepLinkListener.swift
```

## Architecture Rules (Do Not Violate)

1. **Business → facade only.** Call sites use `Mmp.*`. Vendor details stay strictly inside adapters.
2. **`MmpConfig` stays vendor-neutral.** Platform-only options belong on adapter constructors / `*Options` in that module—never in `MmpCore`. Note: `appId` in `MmpConfig` is the Apple App ID required by AppsFlyer on iOS.
3. **Cross-platform capability** → keep alignment with `MmpKit-Android` API and normalized data models.
4. **Out of scope for core** (unless product explicitly asks): customer user id, uninstall tracking, push token, ATT/GDPR consent dialogs, IDFA raw collection.
5. **Thread Safety:** `Mmp` uses `NSRecursiveLock` to protect state, cached attribution, and listener delivery.
6. **Logging:** only via `MmpLog`, gated by `MmpConfig.enableLog` / `Mmp.setLogEnabled`. Never log raw tokens—use `MmpLog.maskToken`. `isDebug` controls **vendor** SDK debug/sandbox only.
7. **Attribution cache:** `Mmp` caches results and exposes sync getters. Adapters must implement `peekAttribution()`. On `initialize`, facade registers an internal attribution listener to keep cache warm even if the app never sets one.
8. **Listener re-delivery:** When `setAttributionListener` is called, re-deliver the cached attribution immediately if already available.
9. **Local simulation support:** Both `AppsFlyerClient` and `AdjustClient` must provide `simulateConversionData` / `simulateAttributionData` and `simulateDeepLink` for local offline/mock testing.

## Public API Surface (`Mmp`)

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

## Vendor Quirks (iOS)

**AppsFlyer**
- `appToken` = Dev Key
- `appId` = Apple App ID (e.g. `123456789`)
- Event names are readable strings
- Revenue: `af_revenue` + `af_currency`
- Deep link: `DeepLinkDelegate` (`didResolveDeepLink`)
- Has `simulateConversionData` / `simulateDeepLink` for local testing

**Adjust**
- `appToken` = App Token
- `MmpEvent.name` / `MmpRevenue.eventName` = **event tokens**
- `isDebug` → sandbox vs production
- Deferred deep links: `adjustDeeplinkResponse` delegate
- Has `simulateAttributionData` / `simulateDeepLink` for local testing

## Build / Verify

```bash
swift test
xcodebuild -project MmpKitDemo.xcodeproj -scheme MmpKitDemo -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO
```
