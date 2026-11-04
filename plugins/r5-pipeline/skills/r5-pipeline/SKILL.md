---
name: r5-pipeline
description: Set up and run a release and CI/CD pipeline on GitHub for any language with mise, Knope changesets, cocogitto commit checks and GitHub Actions, including pre-releases, staging branches, deploy and promotion.
---

# r5-pipeline

## Check the machine
Run `mise --version` and `git --version`. If mise is missing, stop, ask the user to install it (https://mise.jdx.dev/getting-started.html) and wait. Every other tool comes from the project's `mise.toml`: run it with `mise x -- <tool>` or `mise run <task>`.

## Detect
Read first, and let existing files win over templates: `mise.toml`, `knope.toml`, `cog.toml`, `.changeset/`, `.github/workflows/`, `.gitignore`.
- Default branch: `git symbolic-ref --short refs/remotes/origin/HEAD`, else `git branch --show-current`. It replaces `BRANCH` in templates. Never assume `main`.
- Owner and repo: `git remote get-url origin`.
- Language and package manager: pick `references/lang-*.md`. With no match, follow "Other languages" in `references/pipeline.md`.
- Components: one per shippable unit (app, package, service). Ask when unclear.

Ask the user once, in one message, only what you cannot detect:
- Environments to deploy to. Default: `production` only.
- Whether a `staging` branch gates production (storefronts). Default: no.
- The deploy target. Unknown: skip `deploy` and `promote.yml`.

## CLI first
- Read `<tool> --help` and `<tool> <subcommand> --help` before use.
- Create and change files with the tool (`mise use --pin`, `mise tasks add`, `knope document-change`) and review the result. Copy a template only when no command makes the file.

## Set up
1. `mise use --pin cocogitto github:knope-dev/knope <language tools>`, then `mise lock`.
2. Add project-global tasks with `mise tasks add` (commands in `references/mise.md`): `build`, `lint`, `test`, `fmt` where the project has them, plus `lint:commits`, `release:prepare`, `release:publish`, and `deploy` when the target is known. Leave out anything else. Per-package tasks (`dev:<name>`) only for packages that exist now.
3. Copy `templates/knope.toml`, set components and `versioned_files`, run `mise x -- knope --validate`.
4. Copy `templates/cog.toml`. Run `mise x -- cog install-hook commit-msg` once.
5. Copy `templates/workflows/*` into `.github/workflows/`. Replace tokens, pin actions (`references/github.md`), and delete steps for tasks that do not exist. Add `staging.yml` only for a staging branch, `promote.yml` only with a deploy target.
6. No `.gitignore`: copy `templates/gitignore` and add the project's source paths. Otherwise leave it.
7. Check: `mise tasks`, `mise run lint:commits`, `mise x -- knope --validate`.

## Rules
- Every repeatable project-wide command is a mise task. Workflows call `mise run <task>` and hold no logic.
- Pin exact tool versions, commit `mise.lock`, install in CI with `MISE_LOCKED=1`.
- A script over 3 lines or over 3 `&` goes in `scripts/` and a mise task calls it.
- One Knope `[packages.<name>]` per component. Tags are `<name>/vX.Y.Z`. Never `[package]`.
- Every user-facing PR adds a changeset: `knope document-change`.
- Build once. Promotion and rollback deploy the release artifact after `gh attestation verify`.
- Pre-release: dispatch `prepare-release.yml` with a label (alpha, beta, rc). Dispatch with none to graduate.
- No comments in generated or templated files.
- Never run a release, deploy or promotion. Never push or open a PR. Never write a secret to a file.

## Hand off to the user
End with this list, filled in with the real names. Wait for the user to confirm.
1. Repository secret `RELEASE_TOKEN`: a fine-grained token or GitHub App token with Contents and Pull requests write. Settings, Secrets and variables, Actions.
2. Environments (Settings, Environments), one per answer: `production` gets required reviewers and a deployment tag rule `*/v*`. Add each secret and variable `deploy` reads, per environment. Name them from `scripts/deploy.sh` or the deploy task.
3. A ruleset on `BRANCH` (and `staging` if used): require pull requests and the checks from `ci.yml`.
4. In every other clone: `mise x -- cog install-hook commit-msg`.

## References
- `references/pipeline.md`: the flow, branches, environments, staging, pre-releases, monorepo, other languages.
- `references/mise.md`: mise tasks, lock, tool names.
- `references/knope.md`: Knope config, changesets, release PR.
- `references/github.md`: action pinning, environments, rulesets, attestation, promotion.
- `references/lang-node.md`, `references/lang-odin.md`: language specifics.
- `templates/`: `knope.toml`, `cog.toml`, `gitignore`, `workflows/`.
