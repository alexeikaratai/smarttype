@testable import SmartTypeApp

/// Stands in for Carbon: records what would have been registered, and lets a test press it.
final class RecordingRegistrar: HotKeyRegistering {
    var onPress: ((UInt32) -> Void)?
    var refused: Set<KeyCombo> = []
    private(set) var registered: [UInt32: KeyCombo] = [:]

    func register(_ combo: KeyCombo, id: UInt32) -> Bool {
        guard !refused.contains(combo) else { return false }
        registered[id] = combo
        return true
    }

    func unregisterAll() {
        registered.removeAll()
    }

    /// What Carbon does when the person presses a registered combination.
    func press(_ combo: KeyCombo) {
        for (id, registeredCombo) in registered where registeredCombo == combo {
            onPress?(id)
        }
    }
}
