import Carbon.HIToolbox
import SmartTypeCore

/// A keyboard layout on this Mac, with the name macOS gives it in its own language.
nonisolated struct InputSourceLayout: Sendable {
    let layout: KeyboardLayout
    let name: String
}

/// The keyboard layouts enabled in macOS, in the order of its own list (measured), read on
/// every use: 22 µs once the input sources are loaded, 58 ms the first time (measured), so
/// nothing is kept and nothing watches for a change. Main-actor only: HIToolbox aborts the
/// process when two threads call it at once, and says a UI app must call it on the main
/// thread (measured, in a test run).
///
/// What each key types comes from `UCKeyTranslate` with dead keys off, so a dead key types
/// nothing and is left out. U.S. and Russian – PC keep their built-in tables: U.S. reads the
/// same, and Russian – PC's Shift+` types Latin "Ë", which its table knows (both measured).
struct InputSourceLayouts: KeyboardLayoutProviding {
    private static let builtIn = Dictionary(uniqueKeysWithValues: BuiltInLayouts().layouts.map { ($0.id, $0) })

    var layouts: [KeyboardLayout] { Self.read().map(\.layout) }

    /// The enabled ones, or every installed one. Only layouts a person can select: Kana, Hangul,
    /// Pinyin and the like are typed with through an input method, and a fix could never switch
    /// to them (28 of 264 on macOS 27, measured). The one ID macOS lists twice is among them, so
    /// each layout comes once, which a test pins.
    static func read(includingDisabled: Bool = false) -> [InputSourceLayout] {
        let filter =
            [
                kTISPropertyInputSourceType as String: kTISTypeKeyboardLayout as String,
                kTISPropertyInputSourceIsSelectCapable as String: true,
            ] as CFDictionary
        guard let list = TISCreateInputSourceList(filter, includingDisabled)?.takeRetainedValue() as? [TISInputSource]
        else { return [] }
        return list.compactMap(installed)
    }

    // MARK: - Private

    private static func installed(_ source: TISInputSource) -> InputSourceLayout? {
        guard let id: String = property(source, kTISPropertyInputSourceID),
            let name: String = property(source, kTISPropertyLocalizedName)
        else { return nil }
        if let layout = builtIn[id] {
            return InputSourceLayout(layout: layout, name: name)
        }
        guard let keys: Data = property(source, kTISPropertyUnicodeKeyLayoutData) else { return nil }
        let languages: [String] = property(source, kTISPropertyInputSourceLanguages) ?? []
        let typed = typedText(keys)
        let layout = KeyboardLayout(
            id: id, language: Language(code: languages.first ?? "und"), measuredUnshifted: typed.unshifted,
            measuredShifted: typed.shifted)
        return InputSourceLayout(layout: layout, name: name)
    }

    /// What each key of `KeyStroke.ansiKeyCodes` types, without and with Shift.
    private static func typedText(_ keys: Data) -> (unshifted: [String], shifted: [String]) {
        keys.withUnsafeBytes { bytes in
            guard let layout = bytes.baseAddress?.assumingMemoryBound(to: UCKeyboardLayout.self) else {
                return ([], [])
            }
            let keyboardType = UInt32(LMGetKbdType())
            func row(_ modifiers: UInt32) -> [String] {
                KeyStroke.ansiKeyCodes.map { text(layout, key: $0, modifiers: modifiers, keyboardType: keyboardType) }
            }
            return (row(0), row(UInt32(shiftKey >> 8) & 0xFF))
        }
    }

    /// Reads the key table it is given and nothing else, so it needs no thread of its own.
    nonisolated private static func text(
        _ layout: UnsafePointer<UCKeyboardLayout>, key: UInt16, modifiers: UInt32, keyboardType: UInt32
    ) -> String {
        var deadKeyState: UInt32 = 0
        var characters = [UniChar](repeating: 0, count: 4)
        var length = 0
        let status = UCKeyTranslate(
            layout, key, UInt16(kUCKeyActionDown), modifiers, keyboardType, OptionBits(kUCKeyTranslateNoDeadKeysBit),
            &deadKeyState, characters.count, &length, &characters)
        return status == noErr ? String(utf16CodeUnits: characters, count: length) : ""
    }

    private static func property<Value>(_ source: TISInputSource, _ key: CFString) -> Value? {
        guard let raw = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<AnyObject>.fromOpaque(raw).takeUnretainedValue() as? Value
    }
}
