# Changelog

All notable changes to SmartType are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **⌃⌥T translates the selected text** in a panel next to the pointer, on the Mac itself:
  Apple's on-device translation, macOS 26 and later. The language of the text is
  recognized, and it goes into the first of your macOS languages it is not already in; to
  always translate from or into a language of your choice, pick it in Settings ▸
  Translation. The panel is a Liquid Glass card that says which way it translates, keeps
  the original small above the translation, and grows to fit it, from the edge next to the
  pointer. Select the translation, or copy it with ↩. Esc or a click elsewhere closes the
  panel, and your clipboard comes back as it was. A pair of languages not downloaded yet
  comes with a button to the place in System Settings that downloads it. On older macOS,
  Translate is greyed out in the menu and says why.
- SmartType has its own icon: one key with two legends, F and А, since the same key types
  either one depending on the layout, which is the very mix-up SmartType fixes. It shows in
  System Settings' permission lists, which had a blank square for it, and in Settings.
- **⌃⌥L fixes the selected text.** Typed `ghbdtn` with the wrong layout on? Select it, press
  ⌃⌥L, and it becomes `привет` in any app, the keyboard switching to the layout the text is
  now in. A whole selection typed in one layout is converted whole, punctuation included;
  mixed text is decided word by word, with the macOS dictionary as the judge, so
  «Привет, ghbdtn» becomes «Привет, привет». SmartType borrows the clipboard for the copy
  and the paste and puts your own content back, unless you copied something in the
  meantime; clipboard managers are told to skip what it writes. With nothing selected or
  nothing to fix it beeps and changes nothing. Without the permission it needs, it says so
  and offers to grant it, and the menu shows «⚠︎ Grant Access…» until it is granted.
- **Settings…** (⌘,) in the menu opens a Settings window laid out as SmartDock's. General
  shows whether SmartType may use Accessibility (Device Control and Data Access, as
  macOS 27 calls it), which the layout fix needs to copy and paste the selected text,
  with **Grant Access…** and **Reset Permission…**: after an
  update macOS can keep SmartType switched on in the list while the permission no longer
  works, and the reset clears that and restarts SmartType so that macOS lists it again,
  ready to be switched back on; Settings opens next to it to show the status, as in
  SmartDock. Translation picks the languages ⌃⌥T translates from and into, Automatic
  until you choose one. Shortcuts lists both commands and whether macOS accepted them; About shows the version, links to GitHub and the release notes, and
  "Made with ❤ by Alex Karatai". The window is built when it opens and freed when it
  closes, and SmartType still does no work while idle. Esc and ⌘W close it in any
  keyboard layout. On macOS 26 and later the window is Liquid Glass, as the translation
  card is; it follows the light or dark appearance of macOS, and its tabs are grouped as
  in System Settings.
- `make l10n-check` also refuses a bare SwiftUI `Text("…")`: its translation would come
  from a key the check cannot see, so a Russian window could show an English line.
- SmartType runs in the menu bar, with no Dock icon. ⌃⌥L and ⌃⌥T are registered
  system-wide and fire in any keyboard layout, because they are bound to physical keys,
  not letters. The menu lists both commands with their shortcuts, and Keyboard Shortcuts
  shows whether macOS accepted each one. While idle the app uses 0.0% CPU, and about 17 MB
  of memory until Settings is first opened.
- The interface speaks English and Russian and follows the language of macOS; another
  language can be chosen per app in System Settings → General → Language & Region. The
  build refuses to make the app while any string lacks a Russian translation, so a
  Russian menu never shows a stray English word.
- Building, testing, formatting, coverage and versioning all go through `make`, the same
  way as in SmartDock, and CI runs the same checks on every push.
- `make docs-check` fails the build when a link or anchor in the documentation no longer
  resolves, or when CLAUDE.md's file table no longer matches `Sources/`. Docs that drift
  from the code now stop CI instead of misleading the next reader. `make footprint` reports
  the running app's idle CPU, wakeups and memory, so "zero idle cost" is a measurement and
  not a claim.
- The design, before any code: a business plan, an architecture and a delivery plan in
  `docs/`, project instructions in `CLAUDE.md`, a contribution guide and GitHub issue and
  pull request templates. They fix what SmartType is for, how it is built and in what
  order, so the first code lands into decisions already made instead of making them.
