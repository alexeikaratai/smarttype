/// The system side of a global hotkey: watch a combination, report when it is pressed.
/// A seam, so tests never register real hotkeys with the window server.
protocol HotKeyRegistering: AnyObject {
    /// Called with the identifier of a combination that was pressed.
    var onPress: ((UInt32) -> Void)? { get set }
    func register(_ combo: KeyCombo, id: UInt32) -> Bool
    func unregisterAll()
}

// MARK: - HotKeyCenter

/// Gives each hotkey its own identifier and runs its action when the system reports a press.
final class HotKeyCenter {
    private let registrar: any HotKeyRegistering
    private var actions: [UInt32: () -> Void] = [:]
    private var nextID: UInt32 = 1

    init(registrar: any HotKeyRegistering) {
        self.registrar = registrar
        registrar.onPress = { [weak self] id in
            self?.actions[id]?()
        }
    }

    /// Returns `false` when macOS refused the combination; its action is then never kept.
    @discardableResult
    func register(_ combo: KeyCombo, action: @escaping () -> Void) -> Bool {
        let id = nextID
        nextID += 1
        guard registrar.register(combo, id: id) else { return false }
        actions[id] = action
        return true
    }

    func unregisterAll() {
        registrar.unregisterAll()
        actions.removeAll()
    }
}
