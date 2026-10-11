import Carbon.HIToolbox
import Testing

@testable import SmartTypeCore

@Suite struct ANSIKeyCodeTests {
    /// Core cannot import Carbon, so its key codes are plain numbers; this pins them to
    /// Carbon's names, in the row order every built-in layout's strings follow.
    @Test func coreKeyCodesAreCarbonsANSIKeysRowByRow() {
        let carbon = [
            kVK_ANSI_Grave, kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3, kVK_ANSI_4, kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7,
            kVK_ANSI_8, kVK_ANSI_9, kVK_ANSI_0, kVK_ANSI_Minus, kVK_ANSI_Equal,
            kVK_ANSI_Q, kVK_ANSI_W, kVK_ANSI_E, kVK_ANSI_R, kVK_ANSI_T, kVK_ANSI_Y, kVK_ANSI_U, kVK_ANSI_I,
            kVK_ANSI_O, kVK_ANSI_P, kVK_ANSI_LeftBracket, kVK_ANSI_RightBracket, kVK_ANSI_Backslash,
            kVK_ANSI_A, kVK_ANSI_S, kVK_ANSI_D, kVK_ANSI_F, kVK_ANSI_G, kVK_ANSI_H, kVK_ANSI_J, kVK_ANSI_K,
            kVK_ANSI_L, kVK_ANSI_Semicolon, kVK_ANSI_Quote,
            kVK_ANSI_Z, kVK_ANSI_X, kVK_ANSI_C, kVK_ANSI_V, kVK_ANSI_B, kVK_ANSI_N, kVK_ANSI_M,
            kVK_ANSI_Comma, kVK_ANSI_Period, kVK_ANSI_Slash,
        ]
        #expect(KeyStroke.ansiKeyCodes == carbon.map { UInt16($0) })
    }
}
