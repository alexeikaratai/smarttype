import Foundation
import Testing

@testable import SmartTypeCore

/// Webster's Second, as macOS ships it.
private let wordList = "/usr/share/dict/words"

/// The English profile was measured on macOS's word list, and these tests measure it again, so
/// an edit by hand or a change to the list cannot rule out real words unnoticed. They run
/// wherever the list is installed.
@Suite(.enabled(if: FileManager.default.fileExists(atPath: wordList)))
struct EnglishProfileTests {
    /// The lowercase entries: capitalized ones are names.
    private let words: [[Character]]

    init() throws {
        let list = try String(contentsOfFile: wordList, encoding: .utf8)
        words = list.split(separator: "\n").filter { $0 == $0.lowercased() }.map(Array.init)
    }

    @Test func theListIsTheOneTheProfileWasMeasuredOn() {
        #expect(words.count == 210_773)
    }

    /// At most five entries contain each pair, all of them obscure loanwords ("calfkill").
    @Test func everyImpossiblePairIsInAtMostFiveWords() {
        var counts: [String: Int] = [:]
        for word in words {
            for pair in Set(word.indices.dropLast().map { String(word[$0...$0 + 1]) }) {
                counts[pair, default: 0] += 1
            }
        }

        let common = LanguageProfile.english.impossiblePairs.filter { counts[$0, default: 0] > 5 }
        #expect(common.isEmpty)
    }

    /// As a start, only what no entry begins with, so real words such as "if" never trip it.
    @Test func noWordStartsWithAnImpossibleStart() {
        let starts = Set(words.flatMap { [String($0.prefix(1)), String($0.prefix(2))] })

        #expect(LanguageProfile.english.impossibleStarts.isDisjoint(with: starts))
    }
}
