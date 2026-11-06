---
name: r5-bootstrap
description: Bootstrap a GitHub repository for any language, or migrate and update an existing one, to one workflow: mise toolchain, Knope changesets, commit and PR title checks, GitHub Actions release, a docs/WORKFLOW.md for people and agents, then a hand-off of GitHub settings and secrets. Audits first and asks before changing existing files.
---

# r5-bootstrap

## Audit
Read the repo, then print one table: each part below as `present`, `partial`, `different`, `missing` or `skipped (reason)`. It is the task list; update it as parts finish. Set up `missing` parts as in Set up. Anything already in the repo (`partial`, `different`) follows `references/migrate.md`. Never overwrite a file unasked. The goal is every part complete.

| Part | Present when |
|---|---|
| Source and toolchain | a language manifest or source files; `mise.toml` |
| `.gitignore` | allowlist form (`*` first, then `!` lines) |
| README, LICENSE | `README*`, `LICENSE*` exist; LICENSE only when the user names one |
| CODEOWNERS, PR template | `.github/CODEOWNERS`, `.github/pull_request_template.md` |
| `.editorconfig` | file exists |
| `SECURITY.md` | exists; offer only for a public repo |
| Renovate | `renovate.json`; add only when the user says yes. An existing Dependabot config counts as `different` |
| Workflow doc | `docs/WORKFLOW.md`, and `AGENTS.md` or `CLAUDE.md` points to it |
| Commit and PR checks | `cog.toml`, `scripts/lint-commit.sh`, `scripts/check-changeset.sh`, a working commit-msg hook, `pr-title` and `changeset` jobs |
| Release | `knope.toml`, `release.yml`, `prepare-release.yml`; changelog-only: `knope.toml` with a `changelog` workflow |
| Housekeeping | `label-pr.yml`, `stale.yml` |

## Prerequisites
Run `mise --version`, `git --version`, `gh auth status`. On a failure stop, name it, and ask the user to install it (mise: https://mise.jdx.dev/getting-started.html) or run `gh auth login`. A remote not on github.com: ask whether to do repo files only. Work from the repo root; `mise trust` an untrusted config. Every other tool runs as `mise x -- <tool>` or `mise run <task>`.

## Detect
Read the manifests, `mise.toml`, `knope.toml`, `cog.toml`, `.changeset/`, `.github/` and `.gitignore` first.
- Branch: `git ls-remote --symref origin HEAD`, else `gh repo view --json defaultBranchRef`, else the local branch. It replaces `BRANCH`. Never assume `main`.
- Rulesets: `gh api repos/OWNER/REPO/rules/branches/BRANCH`.
- `OWNER`, `REPO`, visibility: `git remote get-url origin`, `gh repo view --json visibility`. No `origin`: ask for `OWNER/REPO` or whether to run `gh repo create`; never create it unasked. Visibility unknown: ask, default private.
- Language and package manager: `references/lang-*.md`, else "Other languages" in `references/pipeline.md`. An existing project: detect and ask nothing. A new one: ask for language, package manager and kind (app, library, service); defaults are in the language reference. Then `git init -b <branch>` and the language's own init command.
- Components: one per shippable unit; the name replaces `app`. Ask when unclear.
- Existing tags, `CHANGELOG.md`, hooks, commitlint or release tooling: `references/migrate.md`. Never run two systems for one job.
- A `scripts/deploy.sh` that already exists is not a deploy target.

Ask in one message, only what you cannot detect, each with its default: new-project language, package manager and kind; `OWNER/REPO` or `gh repo create` when there is no `origin`; visibility (private); release mode or changelog only, no releases (release); link changelog entries to PRs or commits (yes); starting version when the repo has date-based or no versions; components when unclear; solo or team and `@org/team` (solo); license for a public or new project (none; proprietary/internal is an option); environments (`production`); staging branch (no); deploy target (unknown: skip `deploy` and `promote.yml`); Renovate (no); and the questions `migrate.md` calls for. A new project's API sketch comes last (`rules/core.md`).

## Tools
For an unfamiliar tool or flag, read `<tool> --help` and `<tool> <subcommand> --help` first (`mise x --`, `pnpm dlx` or `npx` if not installed). Never write a config from memory. Create and change files with the tool (`mise use --pin`, `mise tasks add`) and review the result; copy a template only when no command makes the file. `knope --generate` and `knope document-change` (task `logchange`) are interactive: do not run them, or instruct the user to run them.

## Set up
1. `mise use --pin cocogitto github:knope-dev/knope <language tools>`, then `mise lock`. An existing `mise.lock` keeps its pins: `git diff mise.lock` shows only new tools.
2. `mise tasks add` (`references/mise.md`): `dev`, `build`, `lint`, `test`, `fmt` where the project has them, plus `lint:title`, `lint:changeset`, `label:pr`, `logchange`, `changelog`, `release:prepare`, `release:publish` (not the `release:*` pair in changelog-only mode), and `deploy` when the target is known. Nothing else. `dev:<name>` only for packages that exist.
3. Copy `templates/knope.toml`; set components and `versioned_files`. No links: delete `[release_notes]`. Changelog-only: `references/knope.md`. Seed a starting version with `--override-version`. No `fmt` task: delete the `mise run fmt` steps. `knope --validate` fails before the first commit, so run it after.
4. Copy `templates/cog.toml` and `templates/scripts/*` to `scripts/`, executable. Install the hook: `mise x -- cog install-hook commit-msg` (`--overwrite` replaces an old one), or inside an existing manager (`references/migrate.md`). Prove it: a bad message must fail to commit.
5. Copy `templates/workflows/*` to `.github/workflows/`. Replace tokens, pin actions (`references/github.md`), delete steps for tasks that do not exist (a `check` job with no steps goes). No `build` task, nothing to ship, or a private repo without Enterprise Cloud: drop the build, attest and `assets` (`references/pipeline.md`). Changelog-only: skip `release.yml`, `prepare-release.yml` and `promote.yml`. `staging.yml` only with a staging branch (also add `staging` to the `push` branches in `ci.yml`), `promote.yml` only with a deploy target. Map each deploy secret into the `deploy` step with `env: NAME: ${{ secrets.NAME }}`.
6. `.gitignore` and the repo files in `references/repo.md`. Add the language's allowlist lines (`references/lang-*.md`). Check: `git ls-files | git check-ignore --no-index --stdin` prints nothing; `git status --porcelain --untracked-files=all` lists no generated files; a probe file (`touch <src>/zz.<ext>`, `git add -A -n`) shows as addable. Delete the probe.
7. Copy `templates/docs/WORKFLOW.md` to `docs/`, replace `BRANCH`, drop whole sections and Checks rows for skipped parts (release, labels, hook); changelog-only replaces Release with the Changelog section in `references/knope.md`. Add `Commits, PRs and releases: follow docs/WORKFLOW.md.` to `AGENTS.md` or `CLAUDE.md`, with the definition of done set to the mise tasks; create a minimal `AGENTS.md` with only that line if neither exists.
8. Check `mise tasks`, then `mise run lint:title -- "feat(app): x"` passes and `-- "feat: x"` fails.

## Rules
- Every repeatable project-wide command is a mise task. Workflows call `mise run <task>` and hold no logic. A script over 3 lines or 3 `&` goes in `scripts/`.
- Pin exact tool versions, commit `mise.lock`, install in CI with `MISE_LOCKED=1`.
- One Knope `[packages.<name>]` per component, tags `<name>/vX.Y.Z`, never `[package]`.
- Every PR adds a changeset by hand or records the changelog locally (`references/knope.md`); the `changeset` check enforces it.
- Build once. Promotion and rollback deploy the attested release artifact.
- No comments in generated or templated files.
- Never run a release, deploy or promotion. Never push, open or merge a PR, or enable auto-merge: only the user merges. Never write a secret to a file.

## Hand off
End with `references/handoff.md`, filled with real names, sections in order. Apply nothing to GitHub. Wait for the user to confirm; the workflows fail until the secrets and environments exist.

## References
- `pipeline.md`: flow, artifacts, environments, staging, pre-releases, monorepo, other languages.
- `migrate.md`: repos that already have part of the stack, and updates.
- `mise.md`, `knope.md`, `github.md`: tool details.
- `repo.md`, `handoff.md`, `lang-node.md`, `lang-odin.md`.
- `templates/`: `knope.toml`, `cog.toml`, `gitignore`, `scripts/`, `workflows/`, `docs/WORKFLOW.md`.
