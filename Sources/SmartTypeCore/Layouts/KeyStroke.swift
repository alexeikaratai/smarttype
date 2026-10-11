/// A physical key, pressed with or without Shift. Layouts are keyed by it, so two layouts
/// pair up by the keys a person pressed, not by the letters they meant.
package struct KeyStroke: Hashable, Sendable {
    package let keyCode: UInt16
    package let shift: Bool

    package init(keyCode: UInt16, shift: Bool) {
        self.keyCode = keyCode
        self.shift = shift
    }

    /// The 47 character keys of an ANSI keyboard, row by row: the order every built-in
    /// layout lists its characters in. Values are macOS virtual key codes (`kVK_ANSI_*`);
    /// a test in the app target pins them to Carbon's constants.
    package static let ansiKeyCodes: [UInt16] = [
        0x32, 0x12, 0x13, 0x14, 0x15, 0x17, 0x16, 0x1A, 0x1C, 0x19, 0x1D, 0x1B, 0x18,  // ` 1 2 3 4 5 6 7 8 9 0 - =
        0x0C, 0x0D, 0x0E, 0x0F, 0x11, 0x10, 0x20, 0x22, 0x1F, 0x23, 0x21, 0x1E, 0x2A,  // q w e r t y u i o p [ ] \
        0x00, 0x01, 0x02, 0x03, 0x05, 0x04, 0x26, 0x28, 0x25, 0x29, 0x27,  // a s d f g h j k l ; '
        0x06, 0x07, 0x08, 0x09, 0x0B, 0x2D, 0x2E, 0x2B, 0x2F, 0x2C,  // z x c v b n m , . /
    ]
}
