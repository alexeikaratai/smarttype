extension KeyboardLayout {
    /// Russian ЙЦУКЕН as macOS's "Russian – PC" layout types it (measured with `UCKeyTranslate`).
    ///
    /// One measured exception: macOS types Latin "Ë" (U+00CB) for Shift+`, not Cyrillic "Ё"
    /// (U+0401). The table holds "Ё", which is what a writer means; the alternative makes
    /// text typed on a real Mac convert back as well.
    package static let russianPC = KeyboardLayout(
        id: "com.apple.keylayout.RussianWin",
        language: .russian,
        unshifted: "ё1234567890-=йцукенгшщзхъ\\фывапролджэячсмитьбю.",
        shifted: "Ё!\"№;%:?*()_+ЙЦУКЕНГШЩЗХЪ/ФЫВАПРОЛДЖЭЯЧСМИТЬБЮ,",
        alternatives: ["\u{00CB}": KeyStroke(keyCode: KeyStroke.ansiKeyCodes[0], shift: true)]
    )
}
