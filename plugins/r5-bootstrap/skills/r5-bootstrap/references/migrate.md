# Migrate and update

One flow for a new repo, a repo with part of the stack, and a repo set up by an earlier run. The end state is the same: every part of the audit table complete or `skipped (reason)`.

## Mode
- Nothing exists: set up every part (`SKILL.md` Set up).
- Some parts exist or are incomplete: migrate.
- Everything exists and the user asks to update: same steps as migrate. The templates are the reference.

## Compare
Run in bash. `T` is this skill's `templates/` folder.
```
T=<skill dir>/templates; B=<branch>; O=<owner>; R=<repo>
render() { sed -E "s/@SHA//; s/BRANCH/$B/g; s/OWNER/$O/g; s/REPO/$R/g" "$1"; }
diff <(sed -E 's/@[0-9a-f]{40}//' .github/workflows/ci.yml) <(render $T/workflows/ci.yml)
```
Repeat for every managed file: workflows, `knope.toml`, `cog.toml`, `scripts/*`, `docs/WORKFLOW.md`. Project values (component names, `versioned_files`, deploy steps) differ on purpose. Class each part:
- `present`: matches the template apart from project values.
- `partial`: lacks a job, step, task, key or section the template has.
- `different`: does the same job another way (another hook manager, release tool, CI).
- `missing`: absent.

Print the table, then work part by part. Do replacements first and `.gitignore` last.

## Ask along the way
Send one message listing every `partial` and `different` part with the diff or gap, the options (keep, merge, replace) and a default for each. Apply nothing until the user replies; a reply of "defaults" accepts them. Never ask about `present` or `missing` parts. Defaults:
- Branch `chore/bootstrap`: yes. Staging files with `git add` or `git rm` is allowed; never commit, push or open a PR.
- `core.hooksPath` set without a manager: write `commit-msg` in that directory running `mise x -- sh scripts/lint-commit.sh --file "$1"`.
- Hook manager (husky, lefthook, pre-commit): keep it and add the check inside it. Husky: write `.husky/commit-msg` (not the generated `.husky/_`), executable. Lefthook: a `commit-msg` entry. pre-commit: a local hook. Replace the `cog install-hook` lines in `docs/WORKFLOW.md` and hand-off section 6 with the manager's install step.
- commitlint: replace (two commit checkers conflict). Remove its config, devDependencies and scripts.
- Release tool already present (release-please, semantic-release): ask. Default keep it and mark Release `skipped (kept <tool>)`. If replaced, remove its config, workflow, devDependencies, scripts and lockfile entries.
- Old cog hook: `mise x -- cog install-hook --overwrite commit-msg`, then prove a bad message fails. Existing clones rerun it.
- An existing CI job that does the work of `check` (for example `test`): do not duplicate it. List their job name as the required check in the hand-off.
- Repo visibility unknown (`gh` cannot see the repo): ask; default private, which drops attest and `assets`.
- Tags: Knope cannot keep `vX.Y.Z` with `[packages.<name>]`. Default: new format, and alias tags for the latest version (`git tag <name>/vX.Y.Z vX.Y.Z^{}`) for the user to push. Without them `knope release` re-releases the current version.
- `.gitignore`: show the diff against the allowlist and convert (below). Default convert.
- Dependabot config present: offer Renovate instead (`references/repo.md`). Default keep Dependabot; its bot PRs are exempt from `changeset`, and its titles need `commit-message.prefix: "chore(deps)"` to pass `pr-title`.
- Start each component at its latest tag's version in `versioned_files`.
- No lockfile: ask to run `<pm> install` once so the user commits it.
- A bootstrap PR itself needs a changeset: write `.changeset/bootstrap.md` with `<component>: chore`. Default yes.
- Pinned tool versions in `mise.toml`: never update unasked.
- A deploy script that already exists is not a known deploy target. Ask, or skip `deploy`.

## Part rules
- **Workflows we manage** (an earlier template of ours): the template wins; show the diff. A job the old template had and the new one lacks (`commits`): show it, default replace, name the replacement. Say when a dropped job did work, such as a build step.
- **The user's own workflow**: add the missing jobs under the template ids (`pr-title`, `changeset`, `check`), keep their jobs. These top-level keys change how their jobs run, so show them and ask: `pull_request.types` including `edited`, `merge_group`, `env.MISE_LOCKED`, `permissions`, `concurrency`. Add `if: github.event.action != 'edited'` to their jobs. Reuse the user's SHA for an action they already pin.
- **mise tasks**: add missing tasks with `mise tasks add`. Never rename existing tasks; map the template step to the existing one.
- **knope.toml**: add missing keys (`extra_changelog_sections`, workflows, `assets` when a `build` task exists). Check every regex `versioned_files` entry against the one in `references/knope.md`; fix a missing suffix group. Keep existing packages and versions. With existing history `knope --validate` works at once.
- **CHANGELOG.md**: Knope inserts a release above the first `## X.Y.Z (date)` heading. Rewrite `## [X.Y.Z] - date` headings to that form after showing the lines. Convert an `[Unreleased]` section into `.changeset/*.md` files, then remove it.
- **`.changeset/README.md`**: Knope fails on a file without front matter. Ask; default delete.
- **README, LICENSE, CODEOWNERS**: never overwrite. Add missing sections after asking.
- **`docs/WORKFLOW.md`**: merge missing sections after asking; keep the project's own.
- **`.gitignore`** (last): convert to the allowlist form.
  1. Copy `templates/gitignore` over `.gitignore`, then add the language lines from `references/lang-*.md`.
  2. Add every tracked file it hides, as directory globs: `git ls-files | git check-ignore --no-index --stdin | sed -E 's|^([^/]+)/.*|\1/**|' | sort -u | sed 's|^|!|' >> .gitignore`.
  3. Repeat the `check-ignore` command; it must print nothing.
  4. Run `git status --short --ignored`. Ask only if it lists untracked files that may be wanted.

## Finish
Re-run the audit. Then hand off (`references/handoff.md`): list the new required checks and tell the user to remove stale ones (`commits`) from the ruleset. `lint:changeset` needs `origin/<base>` and committed changesets.
