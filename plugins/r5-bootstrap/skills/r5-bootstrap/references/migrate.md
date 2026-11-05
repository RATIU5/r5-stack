# Migrate and update

One flow for a new repo, a repo that has some of the stack, and a repo set up by an earlier run. The goal is the same end state everywhere: every part of the audit table complete.

## Mode
- Nothing exists: set up every part (`SKILL.md` Set up).
- Some parts exist or are incomplete: migrate.
- Everything exists and the user asks to update, or the plugin templates changed: update. Same steps as migrate.

## Compare, never assume
For each managed file, render the template (tokens replaced, action SHAs left out) and diff it against the repo file:
```
diff <(sed -E 's/@[0-9a-f]{40}//' .github/workflows/ci.yml) <(sed -E 's/@SHA//; s/BRANCH/main/g' templates/workflows/ci.yml)
```
Class each part:
- `present`: same as the template, ignoring SHAs and project values (names, branch, components, deploy steps).
- `partial`: exists but lacks a job, step, task, key or section the template has.
- `different`: serves the same job another way (another release tool, another hook manager, a custom CI).
- `missing`: absent.

Print the table with these classes, then work part by part.

## Ask along the way
Pause and ask before each of these. One question per part, with the diff or the gap shown, and the options keep, merge, replace:
- `partial` file: show what is missing, offer to add only that. Default: merge.
- `different` part: say which template part it overlaps and what would be lost. Never run two systems for one job. Default: keep theirs, skip our part.
- Anything that deletes or rewrites existing content: show the exact lines first.
- A branch for the work: offer `chore/bootstrap`. Never commit, push or open a PR.
Never ask about a part that is `present` or `missing`; do those. Batch questions that are independent into one message.

## Part rules
- **Workflows**: add a missing job to the existing file under the template's job id (`pr-title`, `changeset`, `check`, `release`, `prepare`). Keep the user's jobs and triggers. Required check names must match `references/handoff.md`.
- **mise tasks**: add missing tasks with `mise tasks add`. Do not rename existing tasks; if one has a different name, map the template step to it.
- **knope.toml**: add missing keys (`extra_changelog_sections`, workflows) without removing packages. Keep existing tags and versions.
- **Hooks**: one hook manager. With husky, lefthook, pre-commit or `core.hooksPath`, add the check inside it.
- **Release tooling or commitlint already present**: ask whether to replace. Replacing means removing the old config and workflow in the same change.
- **`.gitignore`**: convert to the allowlist form, always. Steps:
  1. Copy `templates/gitignore` over `.gitignore`, then add the language lines from `references/lang-*.md`.
  2. Add every tracked file the allowlist hides, as directory globs: `git ls-files | git check-ignore --no-index --stdin | sed -E 's|^([^/]+)/.*|\1/**|' | sort -u | sed 's|^|!|' >> .gitignore`.
  3. Repeat the `check-ignore` command; it must print nothing.
  4. Run `git status --short --ignored`. Show the user what the allowlist now ignores (old ignore rules are gone) and ask if any listed untracked file should be kept.
- **README, LICENSE, CODEOWNERS, `docs/`**: never overwrite. Add missing sections or lines only, after asking.
- **`docs/WORKFLOW.md`**: if one exists, diff it against the template and merge missing sections after asking. Keep the project's own sections.

## Update only
Compare every managed file as above and report the differences as one list. The templates are the reference, so a repo file behind the template is `partial`. Apply the same asks. Never touch project values.

## Finish
Re-run the audit. Every part is `present`, or `skipped (reason)` the user chose. Then hand off (`references/handoff.md`) including any new required check names, which the ruleset must list.
