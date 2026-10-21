/// U.S. and Russian – PC, the pair the first version shipped with. Every other layout is read
/// from macOS, by `InputSourceLayouts` in the app, which keeps these two tables for their IDs.
package struct BuiltInLayouts: Sendable {
    package let layouts: [KeyboardLayout] = [.usQwerty, .russianPC]

    package init() {}
}
