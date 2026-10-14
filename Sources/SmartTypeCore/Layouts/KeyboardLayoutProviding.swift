/// Where keyboard layouts come from: built in today, read from the person's own macOS input
/// sources in Phase 3. Either way the corrector sees the same `KeyboardLayout` values.
package protocol KeyboardLayoutProviding: Sendable {
    var layouts: [KeyboardLayout] { get }
}

// MARK: - BuiltInLayouts

/// U.S. and Russian – PC, the pair the first version ships with.
package struct BuiltInLayouts: KeyboardLayoutProviding {
    package let layouts: [KeyboardLayout] = [.usQwerty, .russianPC]

    package init() {}
}
