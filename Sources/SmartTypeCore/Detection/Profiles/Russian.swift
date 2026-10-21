extension LanguageProfile {
    /// Russian spelling rules rather than a word count, since macOS ships no Russian word list:
    /// - ь and ъ never follow a vowel, and ы never follows a vowel, ь, ъ or й;
    /// - ъ stands only before е, ё, ю, я;
    /// - ж, ш, ч, щ are written with и, а, у, never ы, я, ю (except the loanwords жюри and
    ///   брошюра, so жю and шю stay allowed);
    /// - щ is followed by a vowel, н or ь;
    /// - no word starts with ь, ъ or ы.
    package static let russian = LanguageProfile(
        language: .russian,
        impossiblePairs: [
            "аь еь ёь иь оь уь ыь эь юь яь",
            "аъ еъ ёъ иъ оъ уъ ыъ эъ юъ яъ",
            "аы еы ёы иы оы уы ыы эы юы яы ьы ъы йы",
            "ьь ьъ ъь ъъ йь йъ",
            "ъа ъб ъв ъг ъд ъж ъз ъи ъй ък ъл ъм ън ъо ъп ър ъс ът ъу ъф ъх ъц ъч ъш ъщ ъэ",
            "жы шы чы щы жя шя чя щя чю щю",
            "щб щв щг щд щж щз щй щк щл щм щп щр щс щт щф щх щц щч щш щщ щъ",
        ],
        impossibleStarts: ["ь ъ ы"]
    )
}
