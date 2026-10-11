// Keeps the translations honest. Run by `make l10n-check`, and by `make app` before every bundle.
//
// Usage: swift scripts/l10n-check.swift <catalog.xcstrings> <sources directory>
//
//  1. Every key is a plain literal: `String(localized: "Fix Layout", …)`. The catalog cannot
//     hold an interpolated or computed key, so the English text would show in every language.
//  2. Every key the sources use is in the catalog.
//  3. Every key in the catalog is still used: a stale key is a translation nobody sees.
//  4. Every key has a translated Russian value, so no Russian menu shows an English word.
//
// It reads the sources itself instead of calling `xcstringstool extract`, so the check needs
// nothing from Xcode beyond Swift; CI runs an older Xcode than the dev machine.

import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 3 else {
    print("usage: swift scripts/l10n-check.swift <catalog.xcstrings> <sources directory>")
    exit(2)
}
var problems: [String] = []

// MARK: - Keys in the sources

let call = try NSRegularExpression(pattern: #"String\(\s*localized:"#)
let literalKey = try NSRegularExpression(pattern: #"String\(\s*localized:\s*"((?:[^"\\\n]|\\["\\])*)"\s*[,)]"#)

func keys(in path: String) -> [String] {
    let lines = ((try? String(contentsOfFile: path, encoding: .utf8)) ?? "").split(separator: "\n")
    // Whole-line comments only: a doc comment may mention `String(localized:)` in prose.
    let code = lines.filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }.joined(separator: "\n")
    let range = NSRange(code.startIndex..., in: code)
    let found = literalKey.matches(in: code, range: range).map { match in
        (code as NSString).substring(with: match.range(at: 1))
            .replacingOccurrences(of: #"\""#, with: "\"")
            .replacingOccurrences(of: #"\\"#, with: "\\")
    }
    if found.count != call.numberOfMatches(in: code, range: range) {
        problems.append("\(path): a `String(localized:)` key is not a plain literal")
    }
    return found
}

let sources = (FileManager.default.enumerator(atPath: arguments[2])?.allObjects as? [String] ?? [])
    .filter { $0.hasSuffix(".swift") }
    .map { arguments[2] + "/" + $0 }
let used = Set(sources.flatMap(keys(in:)))

// MARK: - The catalog

guard let data = FileManager.default.contents(atPath: arguments[1]),
    let catalog = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
else {
    print("❌ cannot read \(arguments[1]) as JSON")
    exit(1)
}
let entries = catalog["strings"] as? [String: [String: Any]] ?? [:]

for key in used.subtracting(entries.keys).sorted() {
    problems.append("“\(key)” is used in the sources but missing from the catalog — run: make l10n")
}
for key in Set(entries.keys).subtracting(used).sorted() {
    problems.append("“\(key)” is in the catalog but no longer used — delete it from the catalog")
}
for (key, entry) in entries.sorted(by: { $0.key < $1.key }) where used.contains(key) {
    let russian = (entry["localizations"] as? [String: Any])?["ru"] as? [String: Any]
    let unit = russian?["stringUnit"] as? [String: Any]
    if unit?["state"] as? String != "translated" || (unit?["value"] as? String ?? "").isEmpty {
        problems.append("“\(key)” has no Russian translation")
    }
}

// MARK: - Result

if problems.isEmpty {
    print("✅ \(entries.count) strings, every one used and translated into Russian")
} else {
    problems.forEach { print("❌ \($0)") }
    exit(1)
}
