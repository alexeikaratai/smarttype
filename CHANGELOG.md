# Changelog

All notable changes to SmartType are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- SmartType runs in the menu bar, with no Dock icon. ⌃⌥L and ⌃⌥T are registered
  system-wide and fire in any keyboard layout, because they are bound to physical keys,
  not letters. For now a press is only recorded in the log; fixing the layout and
  translating arrive in the next stages. The menu lists both commands with their shortcuts,
  and «Настройки хоткеев» shows whether macOS accepted each one. While idle the app uses
  0.0% CPU and about 16 MB of memory.
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
