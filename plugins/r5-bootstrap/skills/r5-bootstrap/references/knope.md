# Knope

## Commands
- `knope --generate`: interactive. Use `templates/knope.toml` instead.
- `knope --validate`: no output and exit 0 means valid. It fails in a repo with no commits.
- `knope document-change`: interactive, for humans. It writes the changeset file below. Agents write that file directly.
- `knope prepare-release [--prerelease-label <label>]`: bump versions, write changelogs, run the workflow's other steps. A stable run deletes the changesets; a pre-release run keeps them.
- `knope release`: tag and publish versions that have no release, upload `assets`.
- `--dry-run` on any command prints the plan.
Workflow names in `knope.toml` become subcommands. `prepare-release` is a name from the template, not built in.

## Config
- `[packages.<name>]` keys: `versioned_files`, `changelog`, `scopes`, `assets` (a glob string), `extra_changelog_sections`.
- Native `versioned_files`: Cargo.toml, Cargo.lock, package.json, package-lock.json, deno.json, deno.lock, pyproject.toml, go.mod, pubspec.yaml, pom.xml, gleam.toml, tauri.conf.json.
- Any other file: `{ path = "VERSION", regex = '(?<version>\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+)?)' }`. Do not anchor the regex. Keep the optional suffix group, or pre-releases corrupt the file.
- `[changes] ignore_conventional_commits = true` keeps the changelog to changesets only.
- `[github] owner`, `repo`. The token comes from `GITHUB_TOKEN`.
- `$version` and `$changelog` fail with two or more packages, so release PR text is fixed.
- Pass a pre-release label with the `--prerelease-label` flag only. An empty `KNOPE_PRERELEASE_LABEL` corrupts the version.
- A package name in a changeset that matches no `[packages.<name>]` is ignored silently.
- Below 1.0.0 a `minor` change bumps the patch number. Start components at 1.0.0 or expect this.

## Changeset
```
---
web: minor
---

# Add the thing
```
One `<package>: <type>` line per component. Types: `major`, `minor`, `patch`, plus any type listed in `extra_changelog_sections` (the template has `docs` and `chore`, which add a changelog section and bump the patch version). A stable `prepare-release` deletes the file. Keep only changeset files in `.changeset/`; a `README.md` there breaks `PrepareRelease`. Pending changesets are the unreleased changes; the release PR turns them into the next version heading.

## Release PR
The `prepare-release` workflow switches to branch `release`, runs `PrepareRelease`, commits `chore: prepare release`, force-pushes and runs `CreatePullRequest`. Both release workflows match that commit message, so change it in all three places or none.
Pushes made with `GITHUB_TOKEN` do not trigger workflows, so the release PR needs `RELEASE_TOKEN`.
`PrepareRelease` fails when no changeset names a known package or a file in `.changeset/` has no front matter. The template workflow skips the step when `.changeset/*.md` is empty; a failure after that means a bad package name.
