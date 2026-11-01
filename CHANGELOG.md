# Changelog

All notable changes to the plugins in this repository are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Each plugin is versioned on its own in its `plugin.json`.

## r5-odin

### [0.1.1] - 2026-11-01
#### Changed
- Core rule "Short replies." is now "Keep replies very short."

### [0.1.0]
#### Added
- Skill `odin` with references for syntax, allocators, C mapping, FFI and idiom checks against the core library.
- Skill `odin-mode`, a manual-only working procedure for multi-file changes, design choices and bugs with an unknown cause.
- Agent `odin-coder` for delegated Odin coding, pinned to Sonnet at high effort.
- Core rules, injected at session start only inside Odin projects.
- Guard hooks that deny `git commit`, `git push` and `git merge`, deny newly added comment lines in `.odin` edits, and deny the Fable model on Agent calls.
- Optional odx support. odx is used only when the project root has `odx.json` and `odx --version` succeeds.
- Hook tests and an `odin test` suite for the allocator reference.
