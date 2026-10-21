import AppKit
import Carbon.HIToolbox
import Observation

/// Settings ▸ Shortcuts: each command's shortcut, and the recording of a new one. While a
/// shortcut is recorded the hotkeys are paused, so the keys reach this window, and a key monitor
/// exists; neither outlives the recording.
@Observable final class ShortcutsViewModel {
    /// The command whose shortcut is being recorded.
    private(set) var recording: AppCommand?
    /// The modifiers held while recording, shown as they are pressed.
    private(set) var heldModifiers: Modifiers = []
    /// Why the last combination was refused; the recording goes on.
    private(set) var problem: HotKeyProblem?
    private(set) var shortcuts: [AppCommand: KeyCombo]
    private(set) var refused: Set<AppCommand>

    @ObservationIgnored private let bindings: HotKeyBindings
    @ObservationIgnored private let macOSShortcuts: () -> Set<KeyCombo>
    @ObservationIgnored private let watchKeys: (@escaping (KeyPress) -> Bool) -> () -> Void
    @ObservationIgnored private var stopWatchingKeys: (() -> Void)?
    @ObservationIgnored private var takenByMacOS: Set<KeyCombo> = []

    init(
        bindings: HotKeyBindings,
        macOSShortcuts: @escaping () -> Set<KeyCombo> = { HotKeyRules.macOSShortcuts() },
        watchKeys: @escaping (@escaping (KeyPress) -> Bool) -> () -> Void = { ShortcutsViewModel.watchKeyEvents($0) }
    ) {
        self.bindings = bindings
        self.macOSShortcuts = macOSShortcuts
        self.watchKeys = watchKeys
        shortcuts = bindings.shortcuts
        refused = bindings.refused
    }

    func isDefault(_ command: AppCommand) -> Bool {
        bindings.isDefault(command)
    }

    /// A second click on the field that is recording stops it.
    func toggleRecording(_ command: AppCommand) {
        if recording == command {
            stopRecording()
        } else {
            startRecording(command)
        }
    }

    func startRecording(_ command: AppCommand) {
        if recording == nil {
            bindings.pause()
            takenByMacOS = macOSShortcuts()
            stopWatchingKeys = watchKeys { [weak self] press in self?.handle(press) ?? false }
        }
        recording = command
        heldModifiers = []
        problem = nil
    }

    /// Ends a recording without a new shortcut: Esc, a second click, or the window closing.
    func stopRecording() {
        guard recording != nil else { return }
        bindings.apply()
        endRecording()
    }

    /// Back to the default; a recording under way ends, its pause lifted by the reset.
    func reset(_ command: AppCommand) {
        bindings.reset(command)
        endRecording()
    }

    /// The shortcuts as they are now, for a window that shows them while Settings changes them.
    func refresh() {
        shortcuts = bindings.shortcuts
        refused = bindings.refused
    }

    // MARK: - Private

    /// Keys pressed in SmartType's own windows: a local monitor, which needs no permission.
    private static func watchKeyEvents(_ handler: @escaping (KeyPress) -> Bool) -> () -> Void {
        let monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            let isTaken = MainActor.assumeIsolated { KeyPress(event).map(handler) ?? false }
            return isTaken ? nil : event
        }
        return {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }

    /// Whether the press was taken; a taken one never reaches the window.
    private func handle(_ press: KeyPress) -> Bool {
        guard let command = recording else { return false }
        switch press.kind {
        case .modifiersChanged:
            heldModifiers = press.modifiers
        case .keyDown where press.modifiers.isEmpty && press.keyCode == UInt16(kVK_Escape):
            stopRecording()
        case .keyDown where press.modifiers.isEmpty && [kVK_Delete, kVK_ForwardDelete].contains(Int(press.keyCode)):
            bindings.set(nil, for: command)
            endRecording()
        case .keyDown:
            record(KeyCombo(key: Key(code: press.keyCode), modifiers: press.modifiers), for: command)
        }
        return true
    }

    private func record(_ combo: KeyCombo, for command: AppCommand) {
        if let problem = HotKeyRules.problem(with: combo, for: command, current: shortcuts, macOS: takenByMacOS) {
            self.problem = problem
            return
        }
        bindings.set(combo, for: command)
        endRecording()
    }

    /// The hotkeys are registered by now: `bindings` applies them with every change.
    private func endRecording() {
        stopWatchingKeys?()
        stopWatchingKeys = nil
        recording = nil
        heldModifiers = []
        problem = nil
        refresh()
    }
}
