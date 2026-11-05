---
name: r5-bootstrap
description: Bootstrap a GitHub repository for any language or audit one for gaps. Sets up only what is missing (README, license, CODEOWNERS, PR template, editorconfig, mise toolchain, Knope changesets, cocogitto commit and PR title checks, GitHub Actions release, staging and promotion), then hands off GitHub settings and secrets.
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
| `.editorconfig` | file exists |
| `SECURITY.md` | exists; offer only when the repo is public |
| Renovate | `renovate.json` or Dependabot config exists; offer, add only when the user says yes |
| Workflow doc | `docs/WORKFLOW.md` exists, and `AGENTS.md` or `CLAUDE.md` points to it |
| Commit and PR checks | `cog.toml`, `scripts/lint-commit.sh`, `scripts/check-changeset.sh`, a working commit-msg hook, and `pr-title` and `changeset` jobs in a workflow |
| Release | `knope.toml`, `release.yml`, `prepare-release.yml` |
| Housekeeping | `label-pr.yml`, `stale.yml` |

A workflow file that exists but lacks a job above: show the missing job and ask before merging it in.

## Project type
An existing project: detect language, package manager and tools from its files and ask nothing about them. No project yet, and the prompt does not name them: ask once for language, package manager and project kind (app, library, service), offering the defaults below. Anything unanswered takes the default. New project: run `git init -b <branch>` (the branch from Detect, else `main`), then the language's own init command found with `--help`.
- Node: TypeScript, pnpm, oxc.
- Odin: `odin check`, `odin test`, odinfmt.
- Other: follow "Other languages" in `references/pipeline.md`.

## Research the tool
For any stack the skill has no reference for, or any tool whose flags you are unsure of, run `<tool> --help` and `<tool> <subcommand> --help` first (`pnpm dlx`, `npx` or `mise x --` when it is not installed), then use the real commands. Never write a config from memory.

## Check the machine
Run `mise --version`, `git --version` and `gh auth status`. If one fails, stop, name it, ask the user to install it (mise: https://mise.jdx.dev/getting-started.html) or run `gh auth login`, and wait. A remote that is not on github.com: say this skill targets GitHub Actions and ask whether to continue with repo files only. Every other tool comes from the project's `mise.toml`: run it with `mise x -- <tool>` or `mise run <task>`. Run from the repository root. If mise reports an untrusted config, run `mise trust`.

## Detect
Read first: `mise.toml`, `knope.toml`, `cog.toml`, `.changeset/`, `.github/`, `.gitignore`.
- Default branch: `git ls-remote --symref origin HEAD`, else `gh repo view --json defaultBranchRef`, else the one `git init` made. It replaces `BRANCH` in templates. Never assume `main`.
- Owner, repo and visibility: `git remote get-url origin`, `gh repo view --json visibility`. They replace `OWNER` and `REPO`. The component name replaces `app`.
- No `origin` remote: ask for `OWNER/REPO`, or whether to create it with `gh repo create`. Never create it unasked.
- Existing release tags or `CHANGELOG.md`: read them and start each component at its latest tag version. Knope tags are `<name>/vX.Y.Z`; with only `vX.Y.Z` tags the first `release:publish` tags the current version again. Ask whether to keep the old tag format or accept the new one.
- Existing commit hooks (husky, lefthook, pre-commit, `core.hooksPath`) or commitlint: ask whether to replace them. Never run two.
- Existing release tooling (release-please, semantic-release, the changesets CLI, a release workflow): ask whether to replace it. Never run two.
- Language and package manager: pick `references/lang-*.md`. With no match, follow "Other languages" in `references/pipeline.md`.
- Components: one per shippable unit (app, package, service). Ask when unclear.

Ask once, in one message, only what you cannot detect, offering these defaults:
- Solo or team, and the team handle (`@org/team`). Default: solo.
- License, only when a public or new project has none. Default: none.
- Environments. Default: `production` only. Staging branch gating production (storefronts). Default: no.
- Deploy target. Unknown: skip `deploy` and `promote.yml`.
- Every answer needed from the Detect bullets above (remote, tags, hooks, release tooling, Renovate).
Required checks and the commit convention (Conventional Commits) use the defaults unless the user states otherwise.

## CLI first
- Read `<tool> --help` and `<tool> <subcommand> --help` before use.
- Create and change files with the tool (`mise use --pin`, `mise tasks add`) and review the result. Copy a template only when no command makes the file. `knope --generate` and `knope document-change` are interactive: do not run them.

## Set up
Only for parts the audit marked `missing`. Templates for repo files are in `references/repo.md`.
1. `mise use --pin cocogitto github:knope-dev/knope <language tools>`, then `mise lock`.
2. Add project-global tasks with `mise tasks add` (commands in `references/mise.md`): `build`, `lint`, `test`, `fmt` where the project has them, plus `lint:title`, `lint:changeset`, `label:pr`, `release:prepare`, `release:publish`, and `deploy` when the target is known. Leave out anything else. Per-package tasks (`dev:<name>`) only for packages that exist now.
3. Copy `templates/knope.toml`, set components and `versioned_files`. Validate it after the user's first commit; before any commit `knope --validate` fails.
4. Copy `templates/cog.toml` and `templates/scripts/*` (to `scripts/`, executable). If `git config core.hooksPath` is set, put a `commit-msg` file in that directory that runs `mise x -- sh scripts/lint-commit.sh --file "$1"` (after the user agrees); otherwise run `mise x -- cog install-hook commit-msg` once. Prove it: `git commit` with a bad message must fail.
5. Copy `templates/workflows/*` into `.github/workflows/`. Replace tokens, pin actions (`references/github.md`), and delete steps for tasks that do not exist (`check` may end with none; keep the job only if it has steps). With no `build` task, `release.yml` and `knope.toml` lose the build, attest step and `assets`. Add `staging.yml` (and `staging` to the `push` branches in `ci.yml`) only for a staging branch, `promote.yml` only with a deploy target. A component with nothing to ship, or a private repo without GitHub Enterprise Cloud, loses the attest step and `assets` (see `references/pipeline.md`). Add `env: NAME: ${{ secrets.NAME }}` to the `deploy` step for every deploy secret; environment secrets are not exported on their own.
6. `.gitignore`, README, LICENSE, CODEOWNERS, PR template, `.editorconfig`, `SECURITY.md`, and `renovate.json` only if the user said yes: write the missing ones from `references/repo.md`. Add the language's allowlist lines to `.gitignore` (`references/lang-*.md`). Run `git add -A -n` and confirm every source and config file is listed.
7. Copy `templates/docs/WORKFLOW.md` to `docs/WORKFLOW.md`, replace `BRANCH`, and drop rows or sections for parts that were skipped. Add one line to `AGENTS.md` or `CLAUDE.md`: `Commits, PRs and releases: follow docs/WORKFLOW.md.` Create a minimal `AGENTS.md` holding only that line when neither exists.
8. Check: `mise tasks`, `mise x -- cog --version`. Test `mise run lint:title -- "feat: x"` passes and `-- "bad"` fails.

## Rules
- Every repeatable project-wide command is a mise task. Workflows call `mise run <task>` and hold no logic.
- Pin exact tool versions, commit `mise.lock`, install in CI with `MISE_LOCKED=1`.
- A script over 3 lines or over 3 `&` goes in `scripts/` and a mise task calls it.
- One Knope `[packages.<name>]` per component. Tags are `<name>/vX.Y.Z`. Never `[package]`.
- Every PR adds a changeset, a file `.changeset/<name>.md` in the format in `references/knope.md`. Write it by hand: the CLI is interactive. The `changeset` check enforces it.
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
- `references/repo.md`: README, LICENSE, CODEOWNERS, PR template, .editorconfig, SECURITY.md, Renovate, .gitignore.
- `references/handoff.md`: the hand-off template and defaults.
- `references/lang-node.md`, `references/lang-odin.md`: language specifics.
- `templates/`: `knope.toml`, `cog.toml`, `gitignore`, `scripts/`, `workflows/`, `docs/WORKFLOW.md`.
