# Knope

## Commands
- `knope --generate`: interactive. Use `templates/knope.toml`.
- `knope --validate`: silent exit 0 is valid. It fails with no commits, and when `.changeset/` holds a file without front matter (such as `README.md`).
- `knope document-change`: interactive, for humans. Agents write the changeset file directly.
- `knope prepare-release [--prerelease-label <label>]`: bump versions, write changelogs, run the workflow's other steps. Stable runs delete changesets; pre-releases keep them.
- `knope release`: tag and publish versions with no release, upload `assets`.
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
- Below 1.0.0 a `minor` change bumps the patch number.

## Changeset
```
---
web: minor
---

# Add the thing
```
One `<package>: <type>` line per component. Types: `major`, `minor`, `patch`, and any type in `extra_changelog_sections` (the template adds `docs` and `chore`: own changelog section, patch bump). A package name matching no `[packages.<name>]` is ignored silently. Only changeset files belong in `.changeset/`. Pending changesets are the unreleased changes; the release PR turns them into the next version heading.

## Release PR
`prepare-release` switches to branch `release`, runs `PrepareRelease`, commits `chore: prepare release`, force-pushes and runs `CreatePullRequest`. `release.yml` and `prepare-release.yml` match that commit subject, so change it in all three places or none. Pushes made with `GITHUB_TOKEN` trigger no workflows, so the release PR needs `RELEASE_TOKEN`. `PrepareRelease` fails when no changeset names a known package; the workflow skips it when `.changeset/*.md` is empty.
