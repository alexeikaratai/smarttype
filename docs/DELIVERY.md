# SmartType — Delivery Plan

**Status:** each stage starts on the user's go-ahead. Progress is recorded in `CHANGELOG.md` (`## [Unreleased]`) and in the git history.
**Companion docs:** [Business plan](BUSINESS.md) · [Architecture](ARCHITECTURE.md) · [CLAUDE.md](../CLAUDE.md) · [CONTRIBUTING.md](../CONTRIBUTING.md)

## Principles
- **Every stage ends in a working state.** The app runs, the build is clean with warnings as errors, the tests pass, `CHANGELOG.md` has an entry under `## [Unreleased]`, and the user commits.
- **Targets are added in the stage that gives them content.** There are never empty placeholder targets.
- **AI integrations stay out of the MVP.** Local LLM translation and the LLM judge belong to Phase 2; the architecture reserves their extension points.
- **Branches.** `dev` for work, `main` for releases, as in SmartDock. Commit subjects are in the imperative mood.
- **One process, one toolchain.** The process is in [CLAUDE.md](../CLAUDE.md), and the Makefile is the interface for build, checks and release, mirroring SmartDock.

## Stages
| Step | Scope | Suggested commits | Verification |
|---|---|---|---|
| **0 — Docs & conventions** | `docs/` (business, architecture, delivery); `CLAUDE.md`; `CONTRIBUTING.md`; `CHANGELOG.md`; `README.md`; `.github/` issue and PR templates; `.gitignore` | `Add design docs and project conventions` | the documents are reviewed in the repository |
| **1 — Skeleton & toolchain** | `Package.swift` (`SmartTypeApp` + `SmartType`); `Makefile` (build, test, app, run, install, fix, clean, format, lint, coverage, bump, version-check, docs-check, footprint, doctor, logs, actions-check, help); `Resources/Info.plist`; the README version badge (`VERSION := 0.1.0`, the version being built); `.swift-format`; `ci.yml` + `dependabot.yml`; `.vscode/launch.json`; status menu in English and Russian (String Catalog, `make l10n` / `l10n-check`); Carbon hot keys | `Add SwiftPM package, Makefile and CI`; `Add menu bar app with global hotkeys in English and Russian` (as committed) | `make doctor` / `lint` / `test` / `app` all pass. No Dock icon; hotkeys are logged in both layouts while another app is in front; 0.0% idle CPU. CI is green on `dev` |
| **2 — Layout fix** | in four steps: **2a** `SmartTypeCore` + tests (layouts, converter, detection, corrector); **2b** the Settings window, moved here from Stage 4 so the permission tools exist before the steps that need the permission (builds are ad-hoc, so macOS drops the grant on every rebuild): «Settings…» ⌘, in the menu; General with the Accessibility status, «Grant Access…» and «Reset Permission…»; Shortcuts, read-only; About with "Made with ❤ by Alex Karatai", as in SmartDock; **2c** clipboard transaction, keystrokes, input sources, spelling scorer; **2d** ⌃⌥L end to end, with the Accessibility onboarding alert and «Grant Access…» in the menu while the permission is missing, and the app icon (`scripts/generate-icon.swift`, moved here from Stage 4: System Settings showed a blank square in the permission list). 2c and 2d were built and checked as one step, so the first live check of 2c was ⌃⌥L itself. 2a was committed alone; 2b–2d went in together, because 2b was not yet committed when 2c began | `Add keyboard layouts, converter and language detection`; `Add Settings window and fix the selected text's layout with ⌃⌥L`; then `Switch the layout as the fix lands and open Settings after a reset` (as committed) | Unit tests: `yfgbcfk`→`написал`, `Ghbdtn? rfr ltkf&`→`Привет, как дела?`, `@$^&,`→`";:?б`, `` ` ``→`ё`. TextEdit E2E: the text is fixed, the clipboard restored, the layout switched to Russian – PC. Watch for macOS 27 pasteboard prompts |
| **3 — Translation** | in two steps: **3a** `SmartTypeEngines` + tests (`TranslationEngine`, the chain, the Apple on-device engine, source-language recognition) and the target-language rule in Core; **3b** the floating panel with the SwiftUI card in Liquid Glass, the language picks in Settings ▸ Translation, Settings as a Liquid Glass window with grouped tabs, and ⌃⌥T. Decided 2026-10-12: Apple's engine, macOS 14 kept (translation from 26), any language into the person's pick | `Add translation engine and Apple on-device engine`; `Add translation panel with ⌃⌥T` (as committed) | Panel size, Esc, click outside, focus return, full-screen Spaces. A real ru↔en translation when the languages are installed |
| **3c — Editable shortcuts** | pulled forward from Phase 3 on the user's request (2026-10-12). Defaults ⌃⌥⇧L and ⌃⌥⇧T, one key more than ⌃⌥. Settings ▸ Shortcuts records a new combination (Esc cancels, ⌫ clears, ↺ back to the default) with the hotkeys paused meanwhile, refuses one macOS uses, the other command's, or one without ⌃ (or ⌘ with ⌥), and the menu follows. The stored form, `com.smarttype.shortcut.<command>` = `{keyCode, modifiers}`, is frozen from here | `Make shortcuts editable in Settings` (as committed) | Record ⌃⌥K for Fix Layout: it works in TextEdit at once and after a relaunch, and ⌃⌥⇧L no longer does; ⌘C and ⌃Space are refused with the reason; Esc leaves the shortcut as it was; recording with Russian – PC active shows L; the menu shows the new keys |
| **4 — Context menu & polish** | macOS Services (fix layout, translate), with their menu titles localized through `ServicesMenu.strings`; AX-first selection readers; guards (secure input, empty selection); error states; memory after use back under §1's 40 MB (36–42 MB measured with 3c); the unused `LanguageDetector.dominantLanguage` removed; docs refresh | `Add context-menu commands via macOS Services`; `Read the selection through Accessibility first`; `Guard secure input and empty selections` | In TextEdit, right-click → Services → the layout fix replaces the text, ⌘Z undoes it, and the clipboard is untouched; translate opens the panel. Both commands in TextEdit, Notes, Mail, Safari, VS Code and Telegram, the MVP's apps (BUSINESS §6). `leaks` is clean after a series of actions; idle numbers from `footprint` / `top`; Translation.framework is weak-linked |
| **5 — First release (v0.1.0)** | `release.yml`; `make changelog-check` / `release-notes` / `release`; the cask and formula in `alexeikaratai/homebrew-tap`; LICENSE, MIT (decided 2026-10-12); `dev` merged into `main`, which still holds only Stage 0; ADR-015 reworded without the dev machine's certificates; then the repository made public | `Add release pipeline and Homebrew distribution`; then `make bump V=0.1.0` and the tag | Tag `v0.1.0` → the workflow is green, the GitHub Release body is the CHANGELOG section, the tap is updated, and `brew install --cask alexeikaratai/tap/smarttype` installs and launches on a clean user account |

## Release and distribution

From Stage 5 (v0.1.0), the same pipeline as SmartDock: one tag produces the GitHub Release and the Homebrew update. None of it exists yet.

```
 user:  make bump V=x.y.z ─► notes under [x.y.z] ─► commit ─► tag vx.y.z ─► push the tag
                                                                              │
 release.yml (on v* tag) ◄────────────────────────────────────────────────────┘
   🧪 Test      swift test
   🔨 Build     make bump · make changelog-check · make release-notes · make app · zip
   🎉 Release   SmartType-x.y.z.zip, body = this version's CHANGELOG section
   🍺 Homebrew  alexeikaratai/homebrew-tap, over SSH with TAP_DEPLOY_KEY
                  Casks/smarttype.rb     version + sha256 of the release zip
                  Formula/smarttype.rb   url + sha256 of the source tarball
                fails if any sed matched nothing — a silent no-op once broke SmartDock's formula

 users: brew install --cask alexeikaratai/tap/smarttype      brew upgrade --cask smarttype
```

- **Versioning.** `make bump V=x.y.z` is the only way to change the version. It writes the `Makefile`, `Resources/Info.plist` (short version, and build +1), the README badge and a dated `CHANGELOG.md` section, and finishes with `make version-check`.
- **Release notes.** They are whatever accumulated under `## [Unreleased]`. `make changelog-check` refuses an empty section on both paths (`make release` and `release.yml`).
- **Signing.** Releases are ad-hoc signed. The cask's postflight removes only the quarantine flag (`xattr -dr com.apple.quarantine`), as SmartDock's cask does, so the app opens without a Gatekeeper prompt; `-cr` would clear every extended attribute, ones Homebrew and Finder rely on included. Its caveat reminds the user to grant Accessibility again after an update. Developer ID signing and notarization (`make sign`) come later, once there is a certificate.
- **Cask details.** `depends_on macos: :sonoma`, `uninstall quit: "com.smarttype.app"`, and `zap` removes `~/Library/Preferences/com.smarttype.app.plist`.

**Prerequisites for the first release** (one-time, done by the user):
1. **Make the repository public.** Homebrew cannot download release assets from a private repository. Add the LICENSE at the same time: MIT, decided on 2026-10-12 ([business plan §7](BUSINESS.md#7-business-model-and-distribution)).
2. **Add a deploy key.** Create an SSH key; add the public half to `alexeikaratai/homebrew-tap` as a deploy key with write access, and the private half to this repository as the secret `TAP_DEPLOY_KEY`.
3. **Add the tap files.** Create `Casks/smarttype.rb` and `Formula/smarttype.rb` in the tap, modelled on SmartDock's. The workflow only updates them.

## Verification approach
- **Every code stage** closes against the Definition of Done in [CLAUDE.md](../CLAUDE.md#definition-of-done-a-stage):
  - a clean build with warnings as errors;
  - `make lint`, `make docs-check`, `make test` (new guards proven by mutation), `make coverage`, `make app`;
  - `codesign --verify --strict` and `plutil -lint`, both run by `make app`.
- **End to end.** AppleScript drives TextEdit when the process sending the keystrokes has Accessibility. When it does not (the usual case for Claude), Claude writes a numbered manual checklist with expected results, the user runs it, and Claude confirms what it can from the log.
- **Footprint:** `make footprint` measures idle CPU, wakeups and memory. Stage 1 measured 0.0% CPU, 0 wakeups in 10 s and 17 MB; Stage 2 the same CPU and wakeups, 17 MB until Settings is first opened and 33–34 MB with it open; Stage 3c the same CPU and wakeups, 16 MB at launch and 36–42 MB after Settings and translations, over the 40 MB budget at the top end, which Stage 4c looks into; the numbers are re-checked whenever a stage changes what runs, against the budget in [Architecture §1](ARCHITECTURE.md#1-goals-and-quality-attributes).
- **CI ≠ the dev machine.** CI builds with Xcode 26.x, the dev machine with Xcode 27. A stage is done only when CI is green as well.

## After the MVP
| Phase | Scope |
|---|---|
| **Phase 2 — AI** | an Ollama engine and HTTP transport in front of the Apple engine in the fallback chain; a translation cancelled when its panel closes, which an HTTP engine can honour (Apple's runs on regardless, measured); an LLM judge for ambiguous words |
| **Phase 3 — Auto mode** | Punto-style fixing while typing (`CGEventTap`); the user's installed layouts via `UCKeyTranslate` |
| **v1.0** | launch at login, update detection after `brew upgrade`, Developer ID + notarization, polished onboarding, website |

Details: the [business roadmap](BUSINESS.md#6-product-scope-and-roadmap) and the [extension points in the architecture](ARCHITECTURE.md#7-extension-points-including-future-ai).
