/// Where keyboard layouts come from: built in today, read from the person's own macOS input
/// sources in Phase 3. Either way the corrector sees the same `KeyboardLayout` values.
package protocol KeyboardLayoutProvider: Sendable {
    var layouts: [KeyboardLayout] { get }
}

/// U.S. and Russian – PC, the pair the first version ships with.
package struct BuiltInLayouts: KeyboardLayoutProvider {
    package let layouts: [KeyboardLayout] = [.usQwerty, .russianPC]

    package init() {}
}
