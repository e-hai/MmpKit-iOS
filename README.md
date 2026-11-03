# MmpKit-iOS

iOS 归因（MMP）统一封装库。业务只依赖一套 Swift API，通过替换实现模块切换 **AppsFlyer** / **Adjust** 等平台。

## 模块架构

| 模块 / Target | 说明 |
|---------------|------|
| `MmpCore` | 纯接口、数据模型、`Mmp` 统一门面、`MmpLog`（无第三方 SDK） |
| `MmpAppsFlyer` | AppsFlyer 实现（依赖 `AppsFlyerLib`） |
| `MmpAdjust` | Adjust 实现（依赖 `AdjustSdk` / `Adjust`） |
| `SampleApp` | 演示 App（SwiftUI 响应式界面） |

```
业务 App
  ├─ MmpCore                 （必选）
  └─ MmpAppsFlyer 或 MmpAdjust  （按平台二选一）
```

## 快速接入

### 方式 1：Swift Package Manager (推荐)

在 Xcode 中选择 **File** → **Add Packages...**，输入仓库地址：

```
https://github.com/e-hai/MmpKit-iOS.git
```

按需勾选引入的目标：
- `MmpCore`（必选）
- `MmpAppsFlyer` 或 `MmpAdjust`（二选一）

如果使用 `Package.swift` 声明依赖：

```swift
dependencies: [
    .package(url: "https://github.com/e-hai/MmpKit-iOS.git", from: "1.0.0")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "MmpCore", package: "MmpKit"),
            .product(name: "MmpAppsFlyer", package: "MmpKit"), // 或 MmpAdjust
        ]
    )
]
```

### 方式 2：CocoaPods

在 `Podfile` 中配置：

```ruby
# 引入核心与 AppsFlyer
pod 'MmpKit/AppsFlyer', :git => 'https://github.com/e-hai/MmpKit-iOS.git'

# 或引入核心与 Adjust
# pod 'MmpKit/Adjust', :git => 'https://github.com/e-hai/MmpKit-iOS.git'
```

---

## 使用指南

### 1. 初始化

在 App 启动生命周期（例如 `@main struct App` 的 `init()` 或 `AppDelegate.application(_:didFinishLaunchingWithOptions:)`）中：

```swift
import MmpCore
import MmpAppsFlyer // 或 import MmpAdjust

@main
struct MyApp: App {
    init() {
        let config = MmpConfig(
            appToken: "YOUR_DEV_KEY_OR_APP_TOKEN",
            isDebug: true,                 // 平台 SDK debug / sandbox
            appId: "123456789",            // iOS App Store ID (AppsFlyer 必需)
            enableLog: true                // MmpKit 日志开关
        )

        Mmp.initialize(
            config: config,
            client: AppsFlyerClient()      // 或 AdjustClient()
        )

        // 可选：注册归因监听（支持闭包或协议形式）
        Mmp.setAttributionListener { data in
            print("归因回调通知: \(data.network ?? "nil"), isOrganic: \(data.isOrganic)")
        }

        // 可选：注册深度链接监听
        Mmp.setDeepLinkListener { result in
            print("DeepLink 收到: \(result.deepLinkValue ?? "nil"), deferred: \(result.isDeferred)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

切换平台只需更换 `client: AppsFlyerClient()` 为 `client: AdjustClient()`，业务层代码无需改动。

### 2. 事件与收入上报

```swift
// 普通业务事件
Mmp.trackEvent("level_complete", params: ["level": 3, "score": 100])

// 收入与内购事件
Mmp.trackRevenue(
    MmpRevenue(
        revenue: 9.99,
        currency: "USD",           // ISO 4217
        eventName: "purchase",     // Adjust 下对应后台配置的 event token
        params: ["sku": "coin_pack_s"]
    )
)
```

> **Adjust 注意事项：** `MmpEvent.name` 与 `MmpRevenue.eventName` 对应 Adjust 控制台生成的 **event token**，而非可读事件名称。

### 3. 同步读取归因缓存（推荐）

归因结果会缓存在 `Mmp` 单例中，常见业务判断直接同步读取属性即可（**未就绪时为 `nil`**）：

```swift
if Mmp.isOrganic == true {
    // 判定为自然量用户
}

let network = Mmp.network     // 媒体渠道
let campaign = Mmp.campaign   // 广告活动
let adGroup = Mmp.adGroup     // 广告组
let creative = Mmp.creative   // 广告创意
let data = Mmp.attribution    // 完整归一化 AttributionData 模型
```

| 属性 | 类型 | 说明 |
|------|------|------|
| `Mmp.attribution` | `AttributionData?` | 完整归因缓存 |
| `Mmp.network` | `String?` | 媒体渠道 / 广告网络 |
| `Mmp.campaign` | `String?` | 广告活动名称 |
| `Mmp.adGroup` | `String?` | 广告组 / 广告集 |
| `Mmp.creative` | `String?` | 创意 / 素材标识 |
| `Mmp.clickLabel` | `String?` | 点击标签 |
| `Mmp.isOrganic` | `Bool?` | 是否自然量；`nil` 表示尚未就绪 |

若需主动向服务端刷新归因结果：

```swift
Mmp.getAttribution { data in
    // 异步查询并同步刷新本地缓存
    print("刷新完成: \(String(describing: data))")
}
```

### 4. 运行时日志控制

```swift
Mmp.setLogEnabled(true)
let enabled = Mmp.isLogEnabled()
```

- Tag：`MmpKit`、`MmpKit/AppsFlyer`、`MmpKit/Adjust`
- 敏感 Token（appToken 等）自动脱敏输出（例如 `dev_****1234`）

---

## 演示 Demo (SwiftUI)

`Sample/SampleApp` 提供了完整的交互式体验工程：
- 实时展示初始化状态与 MMP 渠道
- 同步展示 `Mmp.*` 各项缓存属性
- 支持测试业务事件上报、收入上报、异步拉取归因、切换日志等
- 滚动展示实时 Activity Logs

## 环境要求

- iOS 13.0+ / macOS 10.15+
- Swift 5.9+ / Swift 6
- Xcode 15+

## 编码规范

面向 AI 编码助手的约束与开发规范详见 [AGENTS.md](AGENTS.md)。
