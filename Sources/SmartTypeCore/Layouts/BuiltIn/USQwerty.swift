extension KeyboardLayout {
    /// U.S. QWERTY, exactly as macOS's "U.S." layout types it (measured with `UCKeyTranslate`).
    package static let usQwerty = KeyboardLayout(
        id: "com.apple.keylayout.US",
        language: .english,
        unshifted: "`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./",
        shifted: "~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:\"ZXCVBNM<>?"
    )
}
