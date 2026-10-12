// Keeps the documentation honest. Run by `make docs-check` and by CI.
//
//  1. Every relative Markdown link points to a file that exists, and every `#anchor`
//     to a heading in that file, using GitHub's slug rules. docs/ is a private repository
//     cloned in place: its documents are checked where it exists, and CI, which has none,
//     checks the public ones, which therefore name docs/ by path and never link into it.
//  2. CLAUDE.md's file table lists exactly the Swift files under Sources/: a file added
//     without a row, or a row left behind by a deleted file, fails the build.

import Foundation

let documents = ["README.md", "CHANGELOG.md", "CLAUDE.md", "CONTRIBUTING.md", ".github/pull_request_template.md"]
    + ((try? FileManager.default.contentsOfDirectory(atPath: "docs")) ?? [])
        .filter { $0.hasSuffix(".md") }
        .map { "docs/" + $0 }
var problems: [String] = []

func text(of path: String) -> String {
    (try? String(contentsOfFile: path, encoding: .utf8)) ?? ""
}

/// Lines outside fenced code blocks: a `#` or `](` inside code is not Markdown.
func proseLines(of path: String) -> [Substring] {
    var isInFence = false
    return text(of: path).split(separator: "\n", omittingEmptySubsequences: false).filter { line in
        if line.hasPrefix("```") {
            isInFence.toggle()
            return false
        }
        return !isInFence
    }
}

/// GitHub's anchor for a heading: lowercased, punctuation and emoji dropped, spaces to hyphens.
func slug(_ heading: Substring) -> String {
    let kept = heading.lowercased().filter { $0.isLetter || $0.isNumber || $0 == " " || $0 == "-" || $0 == "_" }
    return kept.replacingOccurrences(of: " ", with: "-")
}

func anchors(in path: String) -> Set<String> {
    var result: Set<String> = []
    for line in proseLines(of: path) {
        let level = line.prefix { $0 == "#" }.count
        guard (1...6).contains(level), line.dropFirst(level).first == " " else { continue }
        result.insert(slug(line.dropFirst(level + 1)))
    }
    return result
}

// MARK: - Links and anchors

let link = try NSRegularExpression(pattern: #"\]\(([^)\s]+)\)"#)
for document in documents {
    let directory = (document as NSString).deletingLastPathComponent
    for line in proseLines(of: document) {
        let line = String(line)
        for match in link.matches(in: line, range: NSRange(line.startIndex..., in: line)) {
            let target = (line as NSString).substring(with: match.range(at: 1))
            guard !target.hasPrefix("http"), !target.hasPrefix("mailto:") else { continue }
            let parts = target.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)
            let file = parts[0].isEmpty
                ? document
                : ((directory as NSString).appendingPathComponent(String(parts[0])) as NSString).standardizingPath
            guard FileManager.default.fileExists(atPath: file) else {
                problems.append("\(document): link to \(target) — no such file")
                continue
            }
            if parts.count == 2, !anchors(in: file).contains(String(parts[1])) {
                problems.append("\(document): link to \(target) — no such heading in \(file)")
            }
        }
    }
}

// MARK: - CLAUDE.md file table

let listed = Set(
    text(of: "CLAUDE.md").split(separator: "\n").compactMap { line -> String? in
        guard line.hasPrefix("| `") else { return nil }
        let cell = line.dropFirst(3).prefix { $0 != "`" }
        return cell.hasSuffix(".swift") ? String(cell) : nil
    }
)
let sources = Set(
    (FileManager.default.enumerator(atPath: "Sources")?.allObjects as? [String] ?? [])
        .filter { $0.hasSuffix(".swift") }
)
for missing in sources.subtracting(listed).sorted() {
    problems.append("CLAUDE.md: file table has no row for Sources/\(missing)")
}
for stale in listed.subtracting(sources).sorted() {
    problems.append("CLAUDE.md: file table lists Sources/\(stale), which does not exist")
}

// MARK: - Result

if problems.isEmpty {
    print("✅ Links, anchors and the file table match the repository (\(documents.count) documents, \(sources.count) sources)")
} else {
    problems.forEach { print("❌ \($0)") }
    exit(1)
}
