# Knope

## Commands
- `knope --generate`: interactive. Use `templates/knope.toml`.
- `knope --validate`: silent exit 0 is valid, also with `.changeset/` empty or missing. It fails with no commits, and when `.changeset/` holds a file without front matter (such as `README.md`).
- `knope document-change`: interactive, for humans. Agents write the changeset file directly.
- `knope prepare-release [--prerelease-label <label>]`: bump versions, write changelogs, run the workflow's other steps. Stable runs delete changesets; pre-releases keep them.
- `knope release`: tag and publish every version that has no tag yet, upload `assets`. `--dry-run` prints nothing when every version is tagged; `release.yml` uses that to skip.
- `knope <workflow> --override-version <x.y.z>` sets the version once, for a first release.
- `--dry-run` prints the plan.
Workflow names in `knope.toml` become subcommands; `prepare-release` is a template name.

## Config
- `[packages.<name>]` keys: `versioned_files`, `changelog`, `scopes`, `assets` (a glob string), `extra_changelog_sections`.
- Native `versioned_files`: Cargo.toml, Cargo.lock, package.json, package-lock.json, deno.json, deno.lock, pyproject.toml, go.mod, pubspec.yaml, pom.xml, gleam.toml, tauri.conf.json.
- Any other file: `{ path = "VERSION", regex = '(?<version>\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+)?)' }`. Do not anchor it. Keep the suffix group or pre-releases corrupt the file.
- `[changes] ignore_conventional_commits = true`: the changelog comes from changesets only.
- `[github] owner`, `repo`; the token is `GITHUB_TOKEN`.
- `$version` and `$changelog` fail with two or more packages, so the release PR text is fixed.
- Pass a pre-release label with `--prerelease-label` only; an empty `KNOPE_PRERELEASE_LABEL` corrupts the version.
- Below 1.0.0 a `minor` change bumps the patch number and `major` bumps the minor number. Seed the first version once with `knope changelog --override-version 1.0.0`, never by hand edit.
- `PrepareRelease` fails when no change is pending. `allow_empty = true` makes it exit 0 with nothing written, but the workflow's next `git commit` step still fails, so `prepare-release.yml` keeps its `find .changeset` guard.
- Knope rewrites `package.json` in its own style. The `changelog` and `prepare-release` workflows run `mise run fmt` after `PrepareRelease`; drop that step when the project has no `fmt` task.

## Changeset
```
---
web: minor
---

# Add the thing
```
One `<package>: <type>` line per component. Types: `major`, `minor`, `patch`, and any type in `extra_changelog_sections` (the template adds `docs` and `chore`: own changelog section, patch bump). A package name matching no `[packages.<name>]` is ignored silently. Only changeset files belong in `.changeset/`. Pending changesets are the unreleased changes; the release PR turns them into the next version heading.

## Record locally
`mise run changelog` runs the `changelog` workflow (`PrepareRelease`, then `fmt`). Commit `CHANGELOG.md`, the version bump and the deleted changesets in the feature PR. `check-changeset.sh` passes a PR that changes a `CHANGELOG.md`. In release mode a version recorded this way is tagged when the PR merges, because `release.yml` tags any untagged version. Pre-releases keep their changesets, so locally record stable versions only.

## Changelog-only mode
For "changelog, no releases". `knope.toml` keeps `[packages.<name>]` (no `assets`), `[changes]`, `[release_notes]` when links are wanted, `[github]` only with links, and the `changelog` workflow; delete the `prepare-release` and `release` workflows. Skip `release.yml`, `prepare-release.yml`, `promote.yml`, `RELEASE_TOKEN` and the `release:*` tasks. In `docs/WORKFLOW.md` replace the Release section with:
```
## Changelog
Record the changelog in the feature PR: commit the changeset, open the PR, run `mise run changelog`, commit `CHANGELOG.md`, the version bump and the deleted changesets. Nothing is tagged or published.
```

## Changelog links
Knope has no link switch; `[release_notes] change_templates` in `templates/knope.toml` renders each entry. Knope uses the first template whose variables are all available, so the list runs from most to least specific, each with and without `$details`. Ask in Detect; delete the block for no links.
- `$pr_number`, `$pr_author_login` (Knope 0.23.0+): GitHub API, needs `[github]`, `GITHUB_TOKEN` in the recording job, and a pushed branch with an open PR. Without them Knope warns and falls back to the commit link.
- `$commit_hash`, `$commit_author_name`: the commit that added the change file; none while it is uncommitted.
- `$summary` is the change file title, `$details` its body.
- Knope adds one heading level: `### $summary` renders as `####` under `### Features`.
- Recorded by CI after merge, or locally after the PR is open: PR links. Recorded locally before pushing: commit links for committed changesets, plain entries for uncommitted ones. Commit the changeset first, then run `mise run changelog`. A squash merge drops the branch commit from history; PR links survive it.

Docs: https://knope.tech/reference/config-file/release-notes/, https://knope.tech/recipes/customizing-release-notes/, https://knope.tech/reference/config-file/steps/prepare-release/. Check templates against them, not memory.

## Release PR
`prepare-release` switches to branch `release`, runs `PrepareRelease`, commits `chore: prepare release`, force-pushes and runs `CreatePullRequest`. `prepare-release.yml` matches that commit subject, so change it in both places or none. Pushes made with `GITHUB_TOKEN` trigger no workflows, so the release PR needs `RELEASE_TOKEN`. `PrepareRelease` fails when no changeset names a known package; the workflow skips it when `.changeset/*.md` is empty.
