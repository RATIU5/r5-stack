# Changelog

All notable changes to the plugins in this repository are recorded here, newest first, in one list. Each heading names its plugin and version. Plugins are versioned on their own in `plugin.json`, and a plugin's version changes only when that plugin changes. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]

## [r5-bootstrap 0.2.0] - 2026-11-04

### Changed
- BREAKING: plugin and skill `r5-pipeline` renamed to `r5-bootstrap`, and the tests moved to `tests/r5-bootstrap`. Reinstall with `/plugin install r5-bootstrap@r5-stack`. The version stays 0.2.0.
- The skill audits the repo first, prints each part as present, missing or skipped, and sets up only what is missing. It asks for language, package manager and project kind only when none exists and the prompt names none, and uses defaults for the rest.
- The skill researches a tool's `--help` before writing its config.
- The hand-off follows a fixed template in `references/handoff.md`.

### Added
- `references/repo.md`: small README, LICENSE on request, PR template and `SECURITY.md` for public repos.
- Node projects default to the oxc toolchain (`oxlint`, `oxfmt`, plus `tsc --noEmit` for TypeScript). Odin projects get `odinfmt` and optional `odx`.
- The skill asks whether the repo is solo or team and writes `.github/CODEOWNERS`. Solo repos own everything; team repos can narrow ownership of `.github/` and `mise.toml`.

### Changed
- The ruleset hand-off requires code owner review for teams only, since a solo author cannot approve their own PR.
- Core rules: never commit, push or merge unprompted and never ask first. Commit without confirmation when told. End finished work with a review-and-commit suggestion, a short commit message, and a split suggestion for large changes.

## [r5-odin 0.1.4] - 2026-11-04

### Changed
- Core rules: never commit, push or merge unprompted and never ask first. Commit without confirmation when told. End finished work with a review-and-commit suggestion, a short commit message, and a split suggestion for large changes.

## [r5-pipeline 0.1.1] - 2026-11-04

### Changed
- The skill checks `gh` as well as mise and git, detects the default branch from the remote, and asks before replacing existing release tooling.
- Changesets are written by hand, because `knope document-change` and `knope --generate` are interactive.
- The setup check lints a bounded commit range, so repos with older history pass.
- `RELEASE_TOKEN` is a personal access token, since GitHub App tokens expire after an hour.
- The hand-off no longer sets a tag rule on `production`, which blocked `promote.yml` dispatched from a branch.
- `build` leaves only files in `dist/`. Components with nothing to ship drop the attest and asset steps.
- `promote.yml` verifies the attestation against `release.yml`. `ci.yml` passes the base branch through `env`. `staging.yml` sets `TAG`.
- The session hook stops looking for `mise.toml` at the git root.
- Regex version files keep the pre-release suffix, so beta versions no longer corrupt `VERSION`.
- Deno lists only `deno.json` as a version file. Node is pinned to the LTS. npm and bun deploy commands are spelled out.
- Workflows set permissions per job, disable credential persistence where nothing pushes, and no longer cancel a running staging deploy.
- The setup check no longer lints a commit range that may not exist.

## [r5-pipeline 0.1.0] - 2026-11-04

### Added
- Skill `r5-pipeline`: release and CI/CD setup on GitHub with mise, Knope changesets, cocogitto commit checks and GitHub Actions, for any language. Covers pre-releases, staging branches, deploy and promotion, and a hand-off list of GitHub settings.
- References for the pipeline flow, mise, Knope, GitHub, Node, Bun, Deno, Cloudflare Workers and Odin.
- Templates for `knope.toml`, `cog.toml`, `.gitignore` and the ci, prepare-release, release, promote and staging workflows.
- Core rules, injected at session start inside projects that have `mise.toml` or `knope.toml`.
- Tests in `tests/r5-pipeline`.

## [r5-odin 0.1.3] - 2026-11-01

### Fixed
- The git guard no longer denies a command that only mentions a git command inside quotes, a quoted heredoc or a here-string. Real commands after a heredoc, inside `$( )` or inside `sh -c` are still denied.

## [r5-odin 0.1.2] - 2026-11-01

### Added
- Guard hooks also deny `git pull`, `git rebase`, `git cherry-pick`, `git revert`, `git am`, `gh pr merge` and `gh pr create`.
- Structural test for manifests, frontmatter, size limits and versions, and an opt-in end-to-end script that checks the hooks in real `claude -p` sessions.

### Changed
- The delegation rules call `odin-coder` with an explicit model, and use model haiku for lookups.
- odx guidance uses `odx explain <rule>` and `odx check --max-findings`.
- The PreToolUse matcher is anchored.
- `syntax.md` no longer shows `fallthrough` in its switch example, and the `ffi.md` export examples use a neutral symbol prefix.

## [r5-odin 0.1.1] - 2026-11-01

### Changed
- Core rule "Short replies." is now "Keep replies very short."

## [r5-odin 0.1.0] - 2026-10-31

### Added
- Skill `odin` with references for syntax, allocators, C mapping, FFI and idiom checks against the core library.
- Skill `odin-mode`, a manual-only working procedure for multi-file changes, design choices and bugs with an unknown cause.
- Agent `odin-coder` for delegated Odin coding, pinned to Sonnet at high effort.
- Core rules, injected at session start only inside Odin projects.
- Guard hooks that deny `git commit`, `git push` and `git merge`, deny newly added comment lines in `.odin` edits, and deny the Fable model on Agent calls.
- Optional odx support. odx is used only when the project root has `odx.json` and `odx --version` succeeds.
- Hook tests and an `odin test` suite for the allocator reference.

[Unreleased]: https://github.com/RATIU5/r5-stack/commits/main
[r5-bootstrap 0.2.0]: https://github.com/RATIU5/r5-stack/tree/main/plugins/r5-bootstrap
[r5-odin 0.1.4]: https://github.com/RATIU5/r5-stack/tree/main/plugins/r5-odin
[r5-pipeline 0.1.1]: https://github.com/RATIU5/r5-stack/tree/main/plugins/r5-pipeline
[r5-pipeline 0.1.0]: https://github.com/RATIU5/r5-stack/tree/main/plugins/r5-pipeline
[r5-odin 0.1.3]: https://github.com/RATIU5/r5-stack/tree/main/plugins/r5-odin
[r5-odin 0.1.2]: https://github.com/RATIU5/r5-stack/tree/main/plugins/r5-odin
[r5-odin 0.1.1]: https://github.com/RATIU5/r5-stack/tree/main/plugins/r5-odin
[r5-odin 0.1.0]: https://github.com/RATIU5/r5-stack/tree/main/plugins/r5-odin
