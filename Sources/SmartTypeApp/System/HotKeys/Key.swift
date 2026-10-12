import AppKit
import Carbon.HIToolbox
import SmartTypeCore

/// A physical key by its `kVK_*` code. A shortcut can use the keys named here: the 47
/// character keys, labelled from SmartTypeCore's U.S. layout (measured with `UCKeyTranslate`),
/// and Space, Return, Tab, the two deletes, the arrows, Home, End, Page Up, Page Down and
/// F1–F20. Esc is left out: it cancels a recording.
nonisolated struct Key: Hashable, Sendable {
    let code: UInt16

    static let l = Key(code: UInt16(kVK_ANSI_L))
    static let t = Key(code: UInt16(kVK_ANSI_T))

    var isSupported: Bool { Self.names[code] != nil }

    /// What a U.S. keyboard prints on it: L, 5, ;, Space, F5, →.
    var label: String { Self.names[code]?.label ?? "?" }

    /// What `NSMenuItem.keyEquivalent` takes for it.
    var menuKeyEquivalent: String { Self.names[code]?.menu ?? "" }

    private struct Name: Sendable {
        let label: String
        let menu: String
    }

    private static let names = characterKeys.merging(namedKeys) { character, _ in character }

    private static let characterKeys: [UInt16: Name] = Dictionary(
        uniqueKeysWithValues: KeyStroke.ansiKeyCodes.compactMap { code in
            KeyboardLayout.usQwerty.output[KeyStroke(keyCode: code, shift: false)].map {
                (code, Name(label: $0.uppercased(), menu: $0))
            }
        })

    private static let namedKeys: [UInt16: Name] = {
        var keys: [Int: Name] = [
            kVK_Space: Name(label: String(localized: "Space", comment: "The space bar, in a shortcut"), menu: " "),
            kVK_Return: Name(label: "↩", menu: "\r"),
            kVK_Tab: Name(label: "⇥", menu: "\t"),
            kVK_Delete: Name(label: "⌫", menu: "\u{8}"),
            kVK_ForwardDelete: Name(label: "⌦", menu: function(NSDeleteFunctionKey)),
            kVK_LeftArrow: Name(label: "←", menu: function(NSLeftArrowFunctionKey)),
            kVK_RightArrow: Name(label: "→", menu: function(NSRightArrowFunctionKey)),
            kVK_DownArrow: Name(label: "↓", menu: function(NSDownArrowFunctionKey)),
            kVK_UpArrow: Name(label: "↑", menu: function(NSUpArrowFunctionKey)),
            kVK_Home: Name(label: "↖", menu: function(NSHomeFunctionKey)),
            kVK_End: Name(label: "↘", menu: function(NSEndFunctionKey)),
            kVK_PageUp: Name(label: "⇞", menu: function(NSPageUpFunctionKey)),
            kVK_PageDown: Name(label: "⇟", menu: function(NSPageDownFunctionKey)),
        ]
        let functionKeys = [
            kVK_F1, kVK_F2, kVK_F3, kVK_F4, kVK_F5, kVK_F6, kVK_F7, kVK_F8, kVK_F9, kVK_F10,
            kVK_F11, kVK_F12, kVK_F13, kVK_F14, kVK_F15, kVK_F16, kVK_F17, kVK_F18, kVK_F19, kVK_F20,
        ]
        for (number, code) in zip(1..., functionKeys) {
            keys[code] = Name(label: "F\(number)", menu: function(NSF1FunctionKey + number - 1))
        }
        return Dictionary(uniqueKeysWithValues: keys.map { (UInt16($0.key), $0.value) })
    }()

    /// AppKit's private-use character for a function key, as menus expect it.
    private static func function(_ character: Int) -> String {
        String(utf16CodeUnits: [UInt16(character)], count: 1)
    }
}
