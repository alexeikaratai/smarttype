import Carbon.HIToolbox
import Testing

@testable import SmartTypeApp

/// What the keys pressed during a recording do. When a recording starts and ends is
/// `ShortcutRecordingTests`.
@Suite struct ShortcutsViewModelTests {
    private let controlOptionK = KeyCombo(key: Key(code: UInt16(kVK_ANSI_K)), modifiers: [.control, .option])

    private func model(
        _ registrar: RecordingRegistrar, _ keyboard: KeyMonitorRecorder, macOS: Set<KeyCombo> = [],
        test: String = #function
    ) -> ShortcutsViewModel {
        .forTest(registrar, keyboard, macOS: macOS, test: test)
    }

    @Test func aNewShortcutIsSavedAndWorksAtOnce() {
        let registrar = RecordingRegistrar()
        let keyboard = KeyMonitorRecorder()
        let shortcuts = model(registrar, keyboard)
        shortcuts.startRecording(.fixLayout)

        let isTaken = keyboard.press(kVK_ANSI_K, [.control, .option])

        #expect(isTaken)
        #expect(shortcuts.shortcuts[.fixLayout] == controlOptionK)
        #expect(Set(registrar.registered.values) == [controlOptionK, AppCommand.translate.defaultHotKey])
        #expect(shortcuts.recording == nil)
        #expect(keyboard.watching == 0)
    }

    @Test func escapeCancelsAndBringsTheHotKeysBack() {
        let registrar = RecordingRegistrar()
        let keyboard = KeyMonitorRecorder()
        let shortcuts = model(registrar, keyboard)
        shortcuts.startRecording(.fixLayout)

        keyboard.press(kVK_Escape)

        #expect(shortcuts.shortcuts[.fixLayout] == AppCommand.fixLayout.defaultHotKey)
        #expect(registrar.registered.count == AppCommand.allCases.count)
        #expect(shortcuts.recording == nil)
        #expect(keyboard.watching == 0)
    }

    @Test func deleteLeavesTheCommandWithoutAShortcut() {
        let registrar = RecordingRegistrar()
        let keyboard = KeyMonitorRecorder()
        let shortcuts = model(registrar, keyboard)
        shortcuts.startRecording(.translate)

        keyboard.press(kVK_Delete)

        #expect(shortcuts.shortcuts[.translate] == nil)
        #expect(Set(registrar.registered.values) == [AppCommand.fixLayout.defaultHotKey])
        #expect(shortcuts.recording == nil)
    }

    /// The reason shows, and the person can try other keys straight away.
    @Test func aRefusedCombinationSaysWhyAndKeepsRecording() {
        let registrar = RecordingRegistrar()
        let keyboard = KeyMonitorRecorder()
        let shortcuts = model(registrar, keyboard)
        shortcuts.startRecording(.fixLayout)

        keyboard.press(kVK_ANSI_C, [.command])

        #expect(shortcuts.problem == .needsControlOrCommandOption)
        #expect(shortcuts.recording == .fixLayout)
        #expect(shortcuts.shortcuts[.fixLayout] == AppCommand.fixLayout.defaultHotKey)
        #expect(registrar.registered.isEmpty)
    }

    @Test func aShortcutMacOSUsesIsRefused() {
        let inputSources = KeyCombo(key: Key(code: UInt16(kVK_Space)), modifiers: [.control])
        let keyboard = KeyMonitorRecorder()
        let shortcuts = model(RecordingRegistrar(), keyboard, macOS: [inputSources])
        shortcuts.startRecording(.translate)

        keyboard.press(kVK_Space, [.control])

        #expect(shortcuts.problem == .usedByMacOS)
    }

    @Test func heldModifiersShowWhileRecording() {
        let keyboard = KeyMonitorRecorder()
        let shortcuts = model(RecordingRegistrar(), keyboard)
        shortcuts.startRecording(.fixLayout)

        keyboard.hold([.control, .option])

        #expect(shortcuts.heldModifiers == [.control, .option])
    }

    @Test func resetGoesBackToTheDefault() {
        let registrar = RecordingRegistrar()
        let keyboard = KeyMonitorRecorder()
        let shortcuts = model(registrar, keyboard)
        shortcuts.startRecording(.fixLayout)
        keyboard.press(kVK_ANSI_K, [.control, .option])

        shortcuts.reset(.fixLayout)

        #expect(shortcuts.shortcuts[.fixLayout] == AppCommand.fixLayout.defaultHotKey)
        #expect(shortcuts.isDefault(.fixLayout))
    }
}
