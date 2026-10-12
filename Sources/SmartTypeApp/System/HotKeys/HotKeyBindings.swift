/// Which combination runs which command, as the person set it: kept in `HotKeyStore`,
/// registered with the system, and paused while Settings records a new one.
final class HotKeyBindings {
    /// What a registered combination runs; set once the commands can be performed.
    var perform: (AppCommand) -> Void = { _ in }
    /// The commands whose combination macOS refused at the last `apply()`.
    private(set) var refused: Set<AppCommand> = []

    private let center: HotKeyCenter
    private let store: HotKeyStore

    init(registrar: any HotKeyRegistering, store: HotKeyStore = HotKeyStore()) {
        center = HotKeyCenter(registrar: registrar)
        self.store = store
    }

    /// Every command's shortcut; a cleared one is missing.
    var shortcuts: [AppCommand: KeyCombo] {
        AppCommand.allCases.reduce(into: [:]) { $0[$1] = store.shortcut(for: $1) }
    }

    func isDefault(_ command: AppCommand) -> Bool {
        store.isDefault(command)
    }

    /// `nil` clears it. Registered at once.
    func set(_ combo: KeyCombo?, for command: AppCommand) {
        store.set(combo, for: command)
        apply()
    }

    func reset(_ command: AppCommand) {
        store.reset(command)
        apply()
    }

    /// Registers every command's shortcut afresh: at launch, after a change, after a pause.
    func apply() {
        center.unregisterAll()
        refused = []
        for command in AppCommand.allCases {
            guard let combo = store.shortcut(for: command) else { continue }
            let isRegistered = center.register(combo) { [weak self] in self?.perform(command) }
            if !isRegistered {
                refused.insert(command)
            }
        }
    }

    /// Takes every hotkey away, so the keys reach a window recording a new shortcut instead.
    func pause() {
        center.unregisterAll()
    }
}
