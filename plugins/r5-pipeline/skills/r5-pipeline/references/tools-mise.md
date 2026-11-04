# mise

Checked 2026-11-04. CLI run locally: mise 2026.10.17. Latest release: 2026.11.1. Confirm with `mise --version`. Docs: https://mise.jdx.dev

## Read help first
`mise --help`, then `mise <cmd> --help` for `use`, `install`, `lock`, `run`, `tasks`, `tasks add`, `generate`, `exec`. Do not copy those lists into project docs.

## Commands the pipeline uses
- `mise use --pin <tool>@<version>`: install, write an exact pin to `mise.toml`.
- `mise lock`: write or refresh `mise.lock` (versions, URLs, checksums for every platform) without installing. `--dry-run` previews.
- `mise install --locked` or `MISE_LOCKED=1`: install only what the lock records, fail otherwise.
- `mise run <task>`: run a task and its `depends`. Several: `mise run a ::: b`.
- `mise tasks`: list tasks. `mise tasks add <name> --description "..." -- <cmd>` writes a `[tasks.<name>]` table. `--file` makes a script task instead. `-d` is `--depends`, not a description.
- `mise x -- <cmd>`: run with the project's tools, activated or not.
- `mise generate github-action --task <t>`: prints a workflow that runs one task. `--write` saves it. Use it as the base, then pin actions by SHA.
- `mise generate config`: starter `mise.toml`.

## Lock behavior (verified)
- `mise lock` also records checksums for `github` and `aqua` backends. npm and PyPI record versions only.
- A locked install needs a URL and checksum for the current platform.
- mise-action runs `mise install --locked` itself when `mise.lock` exists (README on main, not checked at v5.2.6). Set `MISE_LOCKED: "1"` in workflows anyway.
- Setting `lockfile = true` in `[settings]` is optional. The docs page does not mark the lockfile experimental.

## Tasks
- `[tasks.<name>]` keys used: `description`, `run` (string or array), `depends`, `dir`, `env`, `sources`, `outputs`.
- File tasks live in `mise-tasks/`. This pipeline uses `scripts/` plus a TOML task instead, so every task shows in one `mise.toml`.
- Task names with `:` need quotes: `[tasks."lint:commits"]`.
- Monorepo tasks: `monorepo_root = true`, a `[monorepo]` table listing `config_roots`, call `mise //apps/web:build`. Documented. Not tested here. `mise tasks graph` and `mise run --affected` exist in 2026.10.17.
- Sharing across repos: `[task_config] includes` takes `git::` URLs and `oci::` refs. Top-level `include` takes a `git::` TOML file, not nested, no `[tasks]` or `[settings]` inside it. Documented, not tested here. Plain HTTP includes are not documented.

## Tools
- Registry names: `node`, `pnpm`, `bun`, `deno`, `cocogitto`, `odin`, `gh`, `clang`. Check any name with `mise registry <name>`.
- `knope` is not in the registry: `github:knope-dev/knope`. Release tags are `knope/v0.23.2`, pin as `knope-v0.23.2`. A bare `0.23.2` fails.
- `odin` is in the registry and resolves to `github:odin-lang/Odin` first.
- `llvm` is not in the registry. `clang` resolves to `conda:clang`, `asdf:mise-plugins/mise-llvm`, `vfox:jdx/vfox-clang`. Not tested for Odin linking.

## github backend
- `"github:owner/repo" = "<version>"` in `[tools]`, or the table form `[tools."github:owner/repo"]` with options.
- Options: `asset_pattern`, `version_prefix`, `bin_path`, `rename_exe`, `filter_bins`, `checksum`, `platforms.<os>-<arch>`.
- Verification: uses the GitHub-reported digest or a release checksum file. Attestation checks run when the release has them. Settings `github.github_attestations` and `github.slsa` default to true. Per tool `github_attestations = false` skips attestation only.
- Locks record the checksum, so later installs compare against it.

## Plugins
- Custom tools use vfox (Lua) plugins. Pin in `[plugins]` as a git URL with `#<commit SHA>`. `mise plugins install --force <name>` reinstalls after a pin change.
- asdf plugins are legacy. The mise docs say the registry accepts no new tools backed by them. `odin` still lists `asdf:jtakakura/asdf-odin` second. Do not use it.

## mise-action
- Pin `jdx/mise-action` by SHA (v5.2.6 in templates). Inputs include `version`, `install`, `install_args`, `cache`, `working_directory`, `experimental`. There is no `locked` input.
- The action installs the newest mise at least 24 hours old unless `version` is set. Pin `version` for reproducible runs.
