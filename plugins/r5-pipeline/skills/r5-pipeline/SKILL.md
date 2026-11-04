---
name: r5-pipeline
description: One-time setup of a release and CI/CD pipeline on GitHub for any language, covering versioning, changelogs, tags, pre-releases, staging branches, deploy and promotion with mise, Knope changesets, cocogitto commit checks and GitHub Actions.
---

# r5-pipeline

## Check the machine
Run `mise --version`, `git --version` and `gh auth status`. If one fails, stop, name it, ask the user to install it (mise: https://mise.jdx.dev/getting-started.html) or run `gh auth login`, and wait. Every other tool comes from the project's `mise.toml`: run it with `mise x -- <tool>` or `mise run <task>`. Run from the repository root. If mise reports an untrusted config, run `mise trust`.

## Detect
Read first, and let existing files win over templates: `mise.toml`, `knope.toml`, `cog.toml`, `.changeset/`, `.github/workflows/`, `.gitignore`.
- Default branch: `git ls-remote --symref origin HEAD`, else `gh repo view --json defaultBranchRef`, else ask. It replaces `BRANCH` in templates. Never assume `main`.
- Owner and repo: `git remote get-url origin`. They replace `OWNER` and `REPO`. The component name replaces `app`.
- Existing release tooling (release-please, semantic-release, the changesets CLI, a release workflow): ask whether to replace it. Never run two.
- Language and package manager: pick `references/lang-*.md`. With no match, follow "Other languages" in `references/pipeline.md`.
- Components: one per shippable unit (app, package, service). Ask when unclear.

Ask the user once, in one message, only what you cannot detect:
- Environments to deploy to. Default: `production` only.
- Whether a `staging` branch gates production (storefronts). Default: no.
- The deploy target. Unknown: skip `deploy` and `promote.yml`.

## CLI first
- Read `<tool> --help` and `<tool> <subcommand> --help` before use.
- Create and change files with the tool (`mise use --pin`, `mise tasks add`) and review the result. Copy a template only when no command makes the file. `knope --generate` and `knope document-change` are interactive: do not run them.

## Set up
1. `mise use --pin cocogitto github:knope-dev/knope <language tools>`, then `mise lock`.
2. Add project-global tasks with `mise tasks add` (commands in `references/mise.md`): `build`, `lint`, `test`, `fmt` where the project has them, plus `lint:commits`, `release:prepare`, `release:publish`, and `deploy` when the target is known. Leave out anything else. Per-package tasks (`dev:<name>`) only for packages that exist now.
3. Copy `templates/knope.toml`, set components and `versioned_files`, run `mise x -- knope --validate`.
4. Copy `templates/cog.toml`. Run `mise x -- cog install-hook commit-msg` once. If it fails because hooks are already managed, tell the user and do not overwrite.
5. Copy `templates/workflows/*` into `.github/workflows/`. Replace tokens, pin actions (`references/github.md`), and delete steps for tasks that do not exist. Add `staging.yml` (and `staging` to the `push` branches in `ci.yml`) only for a staging branch, `promote.yml` only with a deploy target. A component with nothing to ship loses the attest step and `assets` (see `references/pipeline.md`).
6. No `.gitignore`: copy `templates/gitignore` and add the project's source paths. Run `git add -A -n` and confirm every source and config file is listed. Otherwise leave it.
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
End with this list, filled in with the real names. Wait for the user to confirm. The workflows fail until items 1 and 2 are done, so the user does them before the first push.
1. Repository secret `RELEASE_TOKEN`: a fine-grained personal access token with Contents and Pull requests write. Settings, Secrets and variables, Actions. GitHub App tokens expire after an hour and do not work here. Its owner cannot approve the release PR, so a second reviewer must exist.
2. Environments (Settings, Environments), one per answer: `production` gets required reviewers. Add each secret and variable `deploy` reads, per environment. Name them from `scripts/deploy.sh` or the deploy task.
3. A ruleset on `BRANCH` (and `staging` if used): require pull requests and the checks from `ci.yml`.
4. In every other clone: `mise x -- cog install-hook commit-msg`.

## References
- `references/pipeline.md`: the flow, branches, environments, staging, pre-releases, monorepo, other languages.
- `references/mise.md`, `references/knope.md`: tasks, lock, tool names; Knope config, changesets, release PR.
- `references/github.md`: action pinning, environments, rulesets, attestation, promotion.
- `references/lang-node.md`, `references/lang-odin.md`: language specifics.
- `templates/`: `knope.toml`, `cog.toml`, `gitignore`, `workflows/`.
