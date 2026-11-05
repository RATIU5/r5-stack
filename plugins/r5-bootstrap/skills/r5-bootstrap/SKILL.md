---
name: r5-bootstrap
description: Bootstrap a GitHub repository for any language or audit one for gaps. Sets up only what is missing (README, license, CODEOWNERS, PR template, mise toolchain, Knope changesets, cocogitto commit checks, GitHub Actions release, staging and promotion), then hands off GitHub settings and secrets.
---

# r5-bootstrap

## Audit first
Before asking anything, read the repo and print one table: each part below as `present`, `missing` or `skipped (reason)`. Keep it as the task list and update it as parts finish. Set up only `missing` parts. Existing files win over templates.

| Part | Present when |
|---|---|
| Source and toolchain | a language manifest or source files; `mise.toml` |
| `.gitignore` | file exists |
| README | `README*` exists |
| LICENSE | `LICENSE*` exists; skip unless the user names a license |
| CODEOWNERS | `.github/CODEOWNERS` exists |
| PR template | `.github/pull_request_template.md` exists |
| `SECURITY.md` | exists; offer only when the repo is public |
| Commit checks | `cog.toml` and the commit-msg hook |
| Release | `knope.toml`, `.github/workflows/` |

## Project type
An existing project: detect language, package manager and tools from its files and ask nothing about them. No project yet, and the prompt does not name them: ask once for language, package manager and project kind (app, library, service), offering the defaults below. Anything unanswered takes the default. New project: run `git init -b BRANCH`, then the language's own init command found with `--help`.
- Node: TypeScript, pnpm, oxc.
- Odin: `odin check`, `odin test`, odinfmt.
- Other: follow "Other languages" in `references/pipeline.md`.

## Research the tool
For any stack the skill has no reference for, or any tool whose flags you are unsure of, run `<tool> --help` and `<tool> <subcommand> --help` first (`pnpm dlx`, `npx` or `mise x --` when it is not installed), then use the real commands. Never write a config from memory.

## Check the machine
Run `mise --version`, `git --version` and `gh auth status`. If one fails, stop, name it, ask the user to install it (mise: https://mise.jdx.dev/getting-started.html) or run `gh auth login`, and wait. Every other tool comes from the project's `mise.toml`: run it with `mise x -- <tool>` or `mise run <task>`. Run from the repository root. If mise reports an untrusted config, run `mise trust`.

## Detect
Read first: `mise.toml`, `knope.toml`, `cog.toml`, `.changeset/`, `.github/`, `.gitignore`.
- Default branch: `git ls-remote --symref origin HEAD`, else `gh repo view --json defaultBranchRef`, else the one `git init` made. It replaces `BRANCH` in templates. Never assume `main`.
- Owner, repo and visibility: `git remote get-url origin`, `gh repo view --json visibility`. They replace `OWNER` and `REPO`. The component name replaces `app`.
- Existing release tooling (release-please, semantic-release, the changesets CLI, a release workflow): ask whether to replace it. Never run two.
- Language and package manager: pick `references/lang-*.md`. With no match, follow "Other languages" in `references/pipeline.md`.
- Components: one per shippable unit (app, package, service). Ask when unclear.

Ask once, in one message, only what you cannot detect, offering these defaults:
- Solo or team, and the team handle (`@org/team`). Default: solo.
- License, only when a public or new project has none. Default: none.
- Environments. Default: `production` only. Staging branch gating production (storefronts). Default: no.
- Deploy target. Unknown: skip `deploy` and `promote.yml`.
Required checks and the commit convention (Conventional Commits) use the defaults unless the user states otherwise.

## CLI first
- Read `<tool> --help` and `<tool> <subcommand> --help` before use.
- Create and change files with the tool (`mise use --pin`, `mise tasks add`) and review the result. Copy a template only when no command makes the file. `knope --generate` and `knope document-change` are interactive: do not run them.

## Set up
Only for parts the audit marked `missing`. Templates for repo files are in `references/repo.md`.
1. `mise use --pin cocogitto github:knope-dev/knope <language tools>`, then `mise lock`.
2. Add project-global tasks with `mise tasks add` (commands in `references/mise.md`): `build`, `lint`, `test`, `fmt` where the project has them, plus `lint:commits`, `release:prepare`, `release:publish`, and `deploy` when the target is known. Leave out anything else. Per-package tasks (`dev:<name>`) only for packages that exist now.
3. Copy `templates/knope.toml`, set components and `versioned_files`, run `mise x -- knope --validate`.
4. Copy `templates/cog.toml`. Run `mise x -- cog install-hook commit-msg` once. If it fails because hooks are already managed, tell the user and do not overwrite.
5. Copy `templates/workflows/*` into `.github/workflows/`. Replace tokens, pin actions (`references/github.md`), and delete steps for tasks that do not exist. Add `staging.yml` (and `staging` to the `push` branches in `ci.yml`) only for a staging branch, `promote.yml` only with a deploy target. A component with nothing to ship loses the attest step and `assets` (see `references/pipeline.md`).
6. `.gitignore`, README, LICENSE, CODEOWNERS, PR template, `SECURITY.md`: write the missing ones from `references/repo.md`. Run `git add -A -n` and confirm every source and config file is listed.
7. Check: `mise tasks`, `mise x -- cog --version`, `mise x -- knope --validate`. Commit lint runs on real ranges once the user commits.

## Rules
- Every repeatable project-wide command is a mise task. Workflows call `mise run <task>` and hold no logic.
- Pin exact tool versions, commit `mise.lock`, install in CI with `MISE_LOCKED=1`.
- A script over 3 lines or over 3 `&` goes in `scripts/` and a mise task calls it.
- One Knope `[packages.<name>]` per component. Tags are `<name>/vX.Y.Z`. Never `[package]`.
- Every user-facing PR adds a changeset, a file `.changeset/<name>.md` in the format in `references/knope.md`. Write it by hand.
- Build once. Promotion and rollback deploy the release artifact after `gh attestation verify`.
- Pre-release: dispatch `prepare-release.yml` with a label (alpha, beta, rc). Dispatch with none to graduate.
- No comments in generated or templated files.
- Never run a release, deploy or promotion. Never push or open a PR. Never write a secret to a file.

## Hand off to the user
End with the template in `references/handoff.md`, filled with the real names, same sections in the same order. Apply nothing to GitHub yourself. Wait for the user to confirm. The workflows fail until the secrets and environments exist, so the user does them before the first push.

## References
- `references/pipeline.md`: the flow, branches, environments, staging, pre-releases, monorepo, other languages.
- `references/mise.md`, `references/knope.md`: tasks, lock, tool names; Knope config, changesets, release PR.
- `references/github.md`: action pinning, environments, rulesets, attestation, promotion.
- `references/repo.md`: README, LICENSE, CODEOWNERS, PR template, SECURITY.md.
- `references/handoff.md`: the hand-off template and defaults.
- `references/lang-node.md`, `references/lang-odin.md`: language specifics.
- `templates/`: `knope.toml`, `cog.toml`, `gitignore`, `workflows/`.
