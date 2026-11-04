# Verified

Date checked: 2026-11-04. "Tested" means run in a scratch directory. "Docs" means read in official docs by a research subagent. Anything not listed is not verified.

## Versions
| Tool | Version | Source |
|---|---|---|
| mise (CLI used) | 2026.10.17 | tested |
| mise (latest release) | 2026.11.1 | docs |
| Knope | 0.23.2 (2026-10-22) | tested |
| cocogitto | 7.0.0 (2026-03-04) | tested |
| Odin | dev-2026-11a (2026-11-03) | tested |
| gh | 2.103.2 | tested |
| Node, pnpm | v24.21.0, 12.4.1 | tested |
| jdx/mise-action | v5.2.6 | docs |
| actions/checkout, attest | v7.0.1, v4.2.2 | docs |

## Open items
1. Odin asset naming and checksums: verified. Names in `lang-odin.md`. No checksum file or attestation. GitHub digest only.
2. LLVM and clang via mise: changed. `llvm` not in registry. `clang` is, via conda, asdf, vfox. Not tested. Runner provides clang.
3. cocogitto in registry: verified. `cocogitto` maps to `aqua:cocogitto/cocogitto`. Binary `cog`. No `github` backend needed.
4. Knope `VERSION` file: changed. Not native. A `regex` entry works (tested). No Command needed to write it.
5. mise task includes and sharing: verified in docs for 2026.10.17 era. `[task_config] includes` and `include` take `git::`. Not tested across repos.
6. Preview per PR by host: partly verified. See `tools-github.md`. Shopify theme and Netlify not verified.
7. Node lockfile after a Knope bump: changed. pnpm needs no step (tested). `package-lock.json` is native to Knope. bun and deno not tested.

## Corrections to the brief
- Odin is in the mise registry (github backend first).
- `knope prepare-release` is a workflow name in `knope.toml`, not a built-in subcommand.
- `$version` works only with `[package]`, not `[packages.<name>]`.
- `actions/attest-build-provenance` is a wrapper. Use `actions/attest`.
- mise-action has no `locked` input.

## Not verified
Environment tag rule `*/v*`. Ruleset commit message pattern plan. Reusable workflow call limits. mise monorepo tasks. Knope pre-release labels. Real releases (none were run). Whether `ubuntu-latest` ships clang. Preview hosts noted in `tools-github.md`.

## Re-verify
Run `<tool> --version` and compare. If the minor version differs, re-read `<tool> --help` and the tool's docs before using these references.
