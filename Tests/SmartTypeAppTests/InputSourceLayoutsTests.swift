import Carbon.HIToolbox
import Testing

@testable import SmartTypeApp
@testable import SmartTypeCore

/// The layouts macOS ships, read the way Fix Layout reads the enabled ones. Read-only: nothing
/// here enables, selects or changes an input source. On the main actor, since HIToolbox aborts
/// when two threads read the input sources at once (measured: these tests did, in parallel).
@MainActor @Suite struct InputSourceLayoutsTests {
    private let installed: [String: InputSourceLayout] = Dictionary(
        InputSourceLayouts.read(includingDisabled: true).map { ($0.layout.id, $0) },
        uniquingKeysWith: { first, _ in first })

    private func layout(_ id: String) throws -> KeyboardLayout {
        try #require(installed[id]).layout
    }

    /// ABC types what U.S. does on every key (measured), so reading it proves the keys are read in
    /// the built-in order, with and without Shift.
    @Test func abcReadsKeyForKeyAsTheBuiltInUS() throws {
        #expect(try layout("com.apple.keylayout.ABC").output == KeyboardLayout.usQwerty.output)
    }

    /// Russian – PC's Shift+` types Latin "Ë" (measured): its built-in table knows that.
    @Test func russianPCKeepsItsBuiltInTable() throws {
        #expect(try layout(KeyboardLayout.russianPC.id) == .russianPC)
    }

    @Test func ukrainianIsReadWholeInItsLanguage() throws {
        let ukrainian = try layout("com.apple.keylayout.Ukrainian-PC")

        #expect(ukrainian.output.count == KeyStroke.ansiKeyCodes.count * 2)
        #expect(ukrainian.language == Language(code: "uk"))
    }

    /// German's = key is a dead key: it types nothing on its own (measured), so it is left out.
    @Test func aDeadKeyIsLeftOut() throws {
        let equals = KeyStroke(keyCode: UInt16(kVK_ANSI_Equal), isShifted: false)
        #expect(try layout("com.apple.keylayout.German").output[equals] == nil)
    }

    /// The acceptance case: Ukrainian typed with U.S. active comes back as Ukrainian, Shift and
    /// the "і" key included, and the keyboard switches to Ukrainian.
    @Test func ukrainianTypedInUSIsFixed() throws {
        let ukrainian = try layout("com.apple.keylayout.Ukrainian-PC")
        let corrector = LayoutCorrector(
            layouts: [.usQwerty, ukrainian], detector: LanguageDetector(scorers: [PhonotacticScorer()]))

        #expect(corrector.correct("Ghbdsn") == Correction(text: "Привіт", targetLayoutID: ukrainian.id))
    }

    /// Kana, Hangul and Pinyin are layouts only an input method types with: nobody can select
    /// them, so a fix could never switch to them (measured: 28 of 264 on macOS 27).
    @Test func aLayoutNobodyCanSelectIsLeftOut() {
        #expect(installed["com.apple.keylayout.KANA"] == nil)
        #expect(installed["com.apple.keylayout.PinyinKeyboard"] == nil)
    }

    /// macOS lists `TraditionalWubihuaKeyboard` twice, and from 27.2 `WubihuaKeyboard` too
    /// (measured); Settings shows a row per ID, so each is read once.
    @Test func everyLayoutIsReadOnce() {
        let ids = InputSourceLayouts.read(includingDisabled: true).map(\.layout.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func everyLayoutHasTheNameMacOSGivesIt() {
        #expect(!installed.isEmpty)
        #expect(installed.values.allSatisfy { !$0.name.isEmpty })
    }

    /// Apps take a ⌘ shortcut by what its key types with ⌘ held (measured with `UCKeyTranslate`):
    /// Dvorak's C key types ⌘J and Turkish F's ⌘V, while Dvorak – QWERTY ⌘ and Russian – PC
    /// keep ⌘C and ⌘V on the C and V keys.
    @Test(arguments: [
        ("com.apple.keylayout.Dvorak", kVK_ANSI_I, kVK_ANSI_Period),
        ("com.apple.keylayout.Turkish", kVK_ANSI_V, kVK_ANSI_C),
        ("com.apple.keylayout.DVORAK-QWERTYCMD", kVK_ANSI_C, kVK_ANSI_V),
        ("com.apple.keylayout.RussianWin", kVK_ANSI_C, kVK_ANSI_V),
    ])
    func copyAndPasteAreOnTheKeysThatTypeThemWithCommand(_ id: String, _ copy: Int, _ paste: Int) {
        #expect(InputSourceLayouts.commandKey(typing: "c", layoutID: id) == UInt16(copy))
        #expect(InputSourceLayouts.commandKey(typing: "v", layoutID: id) == UInt16(paste))
    }

    /// The layout in use when nothing else is named: on U.S. or Russian – PC, the C key.
    @Test func theLayoutInUseIsReadByDefault() {
        #expect(InputSourceLayouts.commandKey(typing: "c") != nil)
    }
}
