/// Where keyboard layouts come from: built in, or read from the input sources enabled in macOS
/// (`InputSourceLayouts`, in the app). Either way the corrector sees the same `KeyboardLayout`
/// values. Not `Sendable`: macOS's input sources may only be read on the main thread.
package protocol KeyboardLayoutProviding {
    var layouts: [KeyboardLayout] { get }
}

// MARK: - BuiltInLayouts

/// U.S. and Russian – PC, the pair the first version shipped with.
package struct BuiltInLayouts: KeyboardLayoutProviding, Sendable {
    package let layouts: [KeyboardLayout] = [.usQwerty, .russianPC]

    package init() {}
}
