import Carbon.HIToolbox
import Testing

@testable import SmartTypeApp

/// When a recording starts and ends: the hotkeys paused and one key monitor, both only while it
/// lasts. What the keys pressed do is `ShortcutsViewModelTests`.
@Suite struct ShortcutRecordingTests {
    /// Otherwise pressing the current shortcut would run the command instead of being recorded.
    @Test func recordingPausesTheHotKeysAndWatchesTheKeys() {
        let registrar = RecordingRegistrar()
        let keyboard = KeyMonitorRecorder()
        let shortcuts = ShortcutsViewModel.forTest(registrar, keyboard)

        shortcuts.startRecording(.fixLayout)

        #expect(shortcuts.recording == .fixLayout)
        #expect(registrar.registered.isEmpty)
        #expect(keyboard.watching == 1)
    }

    /// A second click on the field, a switch of tab or the window closing ends the recording.
    @Test func stoppingBringsTheHotKeysBack() {
        let registrar = RecordingRegistrar()
        let keyboard = KeyMonitorRecorder()
        let shortcuts = ShortcutsViewModel.forTest(registrar, keyboard)
        shortcuts.toggleRecording(.fixLayout)

        shortcuts.toggleRecording(.fixLayout)

        #expect(shortcuts.recording == nil)
        #expect(registrar.registered.count == AppCommand.allCases.count)
        #expect(keyboard.watching == 0)
    }

    /// Moving to another command's field keeps one recording: one pause, one key monitor.
    @Test func switchingFieldsKeepsOneRecording() {
        let keyboard = KeyMonitorRecorder()
        let shortcuts = ShortcutsViewModel.forTest(RecordingRegistrar(), keyboard)
        shortcuts.startRecording(.fixLayout)

        shortcuts.startRecording(.translate)
        #expect(keyboard.watching == 1)
        keyboard.press(kVK_Escape)

        #expect(keyboard.watching == 0)
    }

    /// ↺ in the middle of a recording ends it, and the hotkeys come back.
    @Test func resetWhileRecordingEndsIt() {
        let registrar = RecordingRegistrar()
        let keyboard = KeyMonitorRecorder()
        let shortcuts = ShortcutsViewModel.forTest(registrar, keyboard)
        shortcuts.startRecording(.fixLayout)

        shortcuts.reset(.translate)

        #expect(shortcuts.recording == nil)
        #expect(keyboard.watching == 0)
        #expect(registrar.registered.count == AppCommand.allCases.count)
    }

    /// Nothing watches the keyboard unless a recording is under way.
    @Test func nothingIsWatchedBeforeARecording() {
        let keyboard = KeyMonitorRecorder()
        _ = ShortcutsViewModel.forTest(RecordingRegistrar(), keyboard)

        #expect(keyboard.watching == 0)
    }
}
