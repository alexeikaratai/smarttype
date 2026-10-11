# Contributing to SmartType

Thanks for taking the time to help. This document covers what you need to build the project, the conventions the codebase follows, and what CI will check on your PR.

> **Status:** the toolchain below is in place. Features land stage by stage, following the [delivery plan](docs/DELIVERY.md#stages).

## Getting set up

**Requirements**

| | Version | Why |
|---|---|---|
| macOS | 14.0+ (Sonoma) | Minimum deployment target. On-device translation needs macOS 26+ |
| Xcode | 26+ | Swift 6.2 first shipped in Xcode 26; earlier versions cannot build the package |
| Swift | 6.2+ | The package declares `swift-tools-version: 6.2` |

SmartType has **no external dependencies**, only Apple frameworks. Clone and build:

```bash
git clone git@github.com:alexeikaratai/smarttype.git
cd smarttype
make doctor   # verifies swift, xcode, swift-format, llvm-cov, codesign, gh, git
make run      # build + bundle + launch
```

If `make doctor` reports a missing tool, fix that first: the other targets assume the toolchain is complete.

## Everyday commands

```bash
make build      # swift build -c release
make test       # swift test (Swift Testing, in parallel)
make format     # rewrite sources with swift-format
make lint       # check formatting without writing — CI gates on this
make coverage   # run tests and print a per-file coverage table
make app        # build + ad-hoc signed .app bundle
make docs-check # links, anchors and the CLAUDE.md file table match the repository
make l10n       # add new UI strings to the translation catalog
make logs       # stream live logs (subsystem com.smarttype.app)
```

`make help` lists everything.

## Before you open a PR

```bash
make format && make lint && make docs-check && make test && make app
```

CI runs the same checks, plus `version-check`, and measures coverage while it tests.

## Code style

Formatting is enforced, not a matter of taste. `.swift-format` at the repo root is the single source of truth (the same configuration as SmartDock), and `make lint` fails the build on any deviation. Run `make format` before committing.

Naming, file organisation, access control, the concurrency rules and the principles behind them are documented in [CLAUDE.md](CLAUDE.md). It is written for an AI assistant but is an accurate description of the house style; read it before a substantial change.

## Architecture in one paragraph

Three targets today, split by isolation domain; a fourth, `SmartTypeEngines`, arrives with translation in Stage 3:
- **`SmartTypeCore`** holds pure logic with no UI: keyboard layouts, conversion, language detection, correction.
- **`SmartTypeEngines`** (Stage 3) will hold the translation engines behind one protocol.
- **`SmartTypeApp`** is the main-actor shell: system adapters (hotkeys, keystrokes, clipboard, input sources, Accessibility), the actions, the menu and the Settings window; the translation panel (Stage 3) and the macOS Services provider (Stage 4) join it.
- **`SmartType`** is the executable, with only `main.swift`.

Dependencies flow one way and never back. **Put logic in Core whenever you can.** Details and decisions are in [ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Testing

```bash
make test
swift test --filter <testName>
```

Tests use **Swift Testing** (`@Suite`, `@Test`, `#expect`) and run in parallel. Conventions:

- Every call that leaves the process is injected with the real thing as the default. That covers synthetic keystrokes, the clipboard, input sources, Accessibility, alerts and translation. Tests pass recorders and never touch the developer's machine.
- Tests use a private `NSPasteboard(name:)`, never the general one.
- Wait for the event, never for a fixed time; a `waitUntil` helper goes into `TestSupport.swift` when the first test needs one.
- Fakes live in each test target's `Mocks.swift`.

## Adding UI text

The interface is English with a Russian translation, and follows the language of macOS.

1. Write the English text through `String(localized: "Fix Layout", comment: "Command: …")`. The English text is the key; the comment tells the translator where it appears. In SwiftUI, pass that string to the view: `Text(String(localized: …))`. A name that is never translated uses `Text(verbatim:)`.
2. Run `make l10n`. It adds the new key to `Resources/Localizable.xcstrings`.
3. Add the Russian value in the catalog, by hand or in Xcode's String Catalog editor.
4. Run `make l10n-check`, which `make app` also runs. It fails on any key that is missing, stale, untranslated or not a plain literal, and on a bare SwiftUI title such as `Text("…")`, whose key it cannot see.

## Versioning

**Never edit a version by hand.**

```bash
make bump V=1.2.3
```

The version appears in the `Makefile`, two keys in `Resources/Info.plist`, the README badge and `CHANGELOG.md`. `make bump` is the only thing that knows all of them, and it finishes with `make version-check`.

## Commits and pull requests

- Branch from `dev` for features; `main` is the release branch.
- Write commit subjects in the imperative mood: "Add layout converter", not "Added" or "Adds".
- Keep formatting-only changes in their own commit.
- Record anything user-visible in `CHANGELOG.md` under `## [Unreleased]`.
- Fill in the PR template.

## Reporting bugs

Open a [bug report](https://github.com/alexeikaratai/smarttype/issues/new?template=bug_report.yml). Say which app you were typing in, which keyboard layouts are enabled, and include a log:

```bash
/usr/bin/log stream --predicate 'subsystem == "com.smarttype.app"' --info --style compact
```

If the layout fix copies or pastes nothing, check Accessibility first; the hotkeys themselves need no permission. Ad-hoc signing changes the binary's code hash on every rebuild, which makes macOS silently revoke the grant.

## License

To be decided before the repository goes public; see the [business plan](docs/BUSINESS.md#7-business-model-and-distribution-to-decide).
