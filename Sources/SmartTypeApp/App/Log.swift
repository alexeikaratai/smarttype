import OSLog

/// Unified logging under the bundle ID. Record at `notice` or above: `.info` and `.debug`
/// are not persisted and never show up in `log show`. User text is never logged.
nonisolated enum Log {
    static let general = Logger(subsystem: subsystem, category: "general")
    static let hotKeys = Logger(subsystem: subsystem, category: "hotkeys")

    private static let subsystem = "com.smarttype.app"
}
