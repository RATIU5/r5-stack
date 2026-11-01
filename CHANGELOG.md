# Changelog

All notable changes to the plugins in this repository are recorded here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Each plugin is versioned on its own in its `plugin.json`.

## r5-odin

### [0.1.3] - 2026-11-01
#### Fixed
- The git guard no longer denies a command that only mentions a git command inside quotes, a quoted heredoc or a here-string. Real commands after a heredoc, inside `$( )` or inside `sh -c` are still denied.

### [0.1.2] - 2026-11-01
#### Added
- Guard hooks also deny `git pull`, `git rebase`, `git cherry-pick`, `git revert`, `git am`, `gh pr merge` and `gh pr create`.
- Structural test for manifests, frontmatter, size limits and versions, and an opt-in end-to-end script that checks the hooks in real `claude -p` sessions.
#### Changed
- The delegation rules call `odin-coder` with an explicit model, and use model haiku for lookups.
- odx guidance uses `odx explain <rule>` and `odx check --max-findings`.
- The PreToolUse matcher is anchored.
- `syntax.md` no longer shows `fallthrough` in its switch example, and the `ffi.md` export examples use a neutral symbol prefix.

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
