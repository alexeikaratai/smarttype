import AppKit
import OSLog

/// Builds the object graph once. The only place that knows the concrete types.
final class AppComposition {
    private let hotKeys: HotKeyCenter
    private let statusBar: StatusBarController
    private(set) var refusedHotKeys: Set<AppCommand> = []

    init(
        hotKeyRegistrar: any HotKeyRegistering = CarbonHotKeyRegistrar(),
        statusBar: NSStatusBar = .system
    ) {
        hotKeys = HotKeyCenter(registrar: hotKeyRegistrar)
        self.statusBar = StatusBarController(statusBar: statusBar)
    }

    func start() {
        for command in AppCommand.allCases {
            let isRegistered = hotKeys.register(command.defaultHotKey) { [weak self] in
                self?.perform(command)
            }
            if !isRegistered {
                refusedHotKeys.insert(command)
            }
        }
        statusBar.show(refusedHotKeys: refusedHotKeys) { [weak self] command in
            self?.perform(command)
        }
    }

    /// The one entry point for every command, whichever door it came through.
    func perform(_ command: AppCommand) {
        Log.general.notice("Command: \(String(describing: command), privacy: .public)")
    }

    /// Takes the status item out of the menu bar; used when a test is done with it.
    func stop() {
        hotKeys.unregisterAll()
        statusBar.remove()
    }
}
