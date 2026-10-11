## What changed

<!-- One or two sentences. What does this PR do, and why? -->

## Why

<!-- The problem being solved. Link the issue if there is one: Fixes #123 -->

## How to verify

<!-- Steps a reviewer can follow. For UI changes, a screenshot or short clip helps.
     For layout-fix, translation or Services changes, say which apps you tried
     (TextEdit, Safari, VS Code…) and which keyboard layouts were enabled —
     that behaviour cannot be verified in CI. -->

---

## Checklist

```bash
make format && make lint && make docs-check && make test && make app
```

- [ ] `make lint` passes — formatting is enforced, not advisory
- [ ] `make docs-check` passes — links, anchors and the CLAUDE.md file table match the code
- [ ] `make test` passes
- [ ] New UI text goes through `String(localized:)` and has a Russian translation (`make l10n-check`)
- [ ] `make app` succeeds — the only thing that exercises bundling and signing
- [ ] New logic that *could* live in `SmartTypeCore` does, and is covered by tests
- [ ] Calls that leave the process are injected, and no test touches the real clipboard,
      input source or Accessibility state
- [ ] Version was **not** edited by hand — use `make bump V=x.y.z` if it needed changing
- [ ] `CHANGELOG.md` updated under `## [Unreleased]` for anything user-visible
- [ ] `CLAUDE.md` / `docs/` / `README.md` updated if this changes architecture, commands or behaviour

### If this PR touches CI or the toolchain

- [ ] The `runs-on:` runner and `XCODE_PATH` still agree — check the
      [runner image readme](https://github.com/actions/runner-images/blob/main/images/macos/macos-26-arm64-Readme.md)
      for which Xcode versions are actually installed
- [ ] `swift-tools-version` in `Package.swift` is supported by the Swift version on that runner

> A version that exists on your Mac is not evidence it exists on the runner.
