# Knope

## Commands
- `knope --generate`: interactive. Use `templates/knope.toml` instead.
- `knope --validate`: no output and exit 0 means valid. It fails in a repo with no commits.
- `knope document-change`: interactive, for humans. It writes the changeset file below. Agents write that file directly.
- `knope prepare-release [--prerelease-label <label>]`: bump versions, write changelogs, delete changesets, run the workflow's other steps.
- `knope release`: tag and publish versions that have no release, upload `assets`.
- `--dry-run` on any command prints the plan.
Workflow names in `knope.toml` become subcommands. `prepare-release` is a name from the template, not built in.

## Config
- `[packages.<name>]` keys: `versioned_files`, `changelog`, `scopes`, `assets` (a glob string), `extra_changelog_sections`.
- Native `versioned_files`: Cargo.toml, Cargo.lock, package.json, package-lock.json, deno.json, deno.lock, pyproject.toml, go.mod, pubspec.yaml, pom.xml, gleam.toml, tauri.conf.json.
- Any other file: `{ path = "VERSION", regex = '(?<version>\d+\.\d+\.\d+)' }`. Do not anchor the regex.
- `[changes] ignore_conventional_commits = true` keeps the changelog to changesets only.
- `[github] owner`, `repo`. The token comes from `GITHUB_TOKEN`.
- `$version` and `$changelog` work only with `[package]`, so release PR text is fixed.
- Below 1.0.0 a `minor` change bumps the patch number. Start components at 1.0.0 or expect this.

## Changeset
```
---
web: minor
---

# Add the thing
```
One `<package>: major|minor|patch` line per component. `prepare-release` deletes the file.

## Release PR
The `prepare-release` workflow switches to branch `release`, runs `PrepareRelease`, commits `chore: prepare release`, force-pushes and runs `CreatePullRequest`. Both release workflows match that commit message, so change it in all three places or none.
Pushes made with `GITHUB_TOKEN` do not trigger workflows, so the release PR needs `RELEASE_TOKEN`.
A run with no changesets fails `PrepareRelease` and shows as a failed job. Read the log before assuming a fault.
