import Foundation

/// MmpKit 统一内部日志器。
///
/// 默认关闭；可通过 `MmpConfig.enableLog` 或 `Mmp.setLogEnabled(_:)` 动态开关。
public final class MmpLog {
    public static let tag = "MmpKit"

    private static let lock = NSLock()
    private static var _enabled: Bool = false

    public static var enabled: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _enabled
        }
        set {
            lock.lock()
            _enabled = newValue
            lock.unlock()
        }
    }

    public static func d(_ message: String, tag: String = MmpLog.tag) {
        guard enabled else { return }
        log(level: "DEBUG", tag: tag, message: message)
    }

    public static func i(_ message: String, tag: String = MmpLog.tag) {
        guard enabled else { return }
        log(level: "INFO", tag: tag, message: message)
    }

    public static func w(_ message: String, tag: String = MmpLog.tag) {
        guard enabled else { return }
        log(level: "WARN", tag: tag, message: message)
    }

    public static func e(_ message: String, error: Error? = nil, tag: String = MmpLog.tag) {
        guard enabled else { return }
        let errStr = error != nil ? " (Error: \(error!.localizedDescription))" : ""
        log(level: "ERROR", tag: tag, message: "\(message)\(errStr)")
    }

    private static func log(level: String, tag: String, message: String) {
        print("[\(level)][\(tag)] \(message)")
    }

    /// 对敏感 Token 脱敏，例如 `abcd****wxyz`。
    public static func maskToken(_ token: String?) -> String {
        guard let token = token, !token.isEmpty else { return "<empty>" }
        if token.count <= 8 { return "****" }
        let prefix = token.prefix(4)
        let suffix = token.suffix(4)
        return "\(prefix)****\(suffix)"
    }
}
