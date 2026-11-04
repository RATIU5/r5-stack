# Knope

Checked 2026-11-04 against Knope 0.23.2 (released 2026-10-22). Confirm with `knope --version`. Docs: https://knope.tech

## Read help first
`knope --help`, `knope document-change --help`, `knope release --help`. After `knope.toml` defines workflows, `knope --help` lists those workflow names as the subcommands. `prepare-release` is a workflow name from the config, not a built-in.

## Commands the pipeline uses
- `knope --generate`: write a starter `knope.toml` (refuses if one exists). Reads `package.json` etc. Run it, then reshape into `[packages.<name>]`.
- `knope --validate`: check the config. Exit 0 and no output means valid.
- `knope document-change`: create `.changeset/<name>.md`. Needs a workflow with a `CreateChangeFile` step once you define workflows.
- `knope prepare-release`: bump versions, write changelog, delete changesets, stage files, run the Command and CreatePullRequest steps.
- `knope release`: create tags and GitHub releases for versions without a release.
- `--dry-run`: print what would happen, change nothing. `--prerelease-label <label>` or `KNOPE_PRERELEASE_LABEL` sets the label at runtime. `--override-version`.

## Config rules
- `[packages.<name>]` keys: `versioned_files`, `changelog`, `scopes`, `assets`, `extra_changelog_sections`.
- Native `versioned_files` by file name: Cargo.toml, Cargo.lock, package.json, package-lock.json, deno.json, deno.lock, pyproject.toml, go.mod, pubspec.yaml, pom.xml, gleam.toml, tauri.conf.json.
- A plain `VERSION` file is not native (error `Unknown file: VERSION`). Use `{ path = "VERSION", regex = '(?<version>\d+\.\d+\.\d+)' }`. The regex must be unanchored (an `^...$` form did not match). Tested.
- `[github] owner, repo`. Token from `GITHUB_TOKEN`.
- `[changes] ignore_conventional_commits = true` keeps commits out of the changelog.

## Changeset
```
---
web: minor
---

# Add the thing
```
One `<package>: <type>` per line. Highest type wins. `PrepareRelease` deletes the file. Default sections: major Breaking Changes, minor Features, patch Fixes. In 0.x, `minor` produced a patch bump in testing.

## Steps used
`PrepareRelease`, `Release`, `CreateChangeFile`, `Command`, `CreatePullRequest`. Others exist (`BumpVersion`, `RebaseBranch`, `SwitchBranches`, issue steps). Read the step page on knope.tech before using one.

## Variables
`$version` and `$changelog` work only with the single `[package]` form. With `[packages.<name>]` they are unavailable, so the release PR title and body are fixed text and a file like `VERSION` is written through `versioned_files`, not a Command.

## Release PR flow
Follows the official recipe (knope.tech recipes, "Preview releases with pull requests"):
1. Push to `main` runs `prepare-release.yml`, which runs `mise run release:prepare`.
2. The workflow `prepare-release` switches to branch `release`, runs `PrepareRelease`, commits, force-pushes, opens or updates the PR into `main`.
3. Merging the PR pushes to `main`. `release.yml` sees the commit message `chore: prepare release`, builds, attests, runs `mise run release:publish`.
4. `Release` tags `<package>/vX.Y.Z` for each package whose version has no release, uploads `assets`.
- The prepare job skips its own merge commit with an `if` on the message. If you change the message, change both workflows.
- The recipe uses `continue-on-error` because a push with no changes makes `PrepareRelease` fail. That also hides real errors. Read the job log.
- A PR created with `GITHUB_TOKEN` does not trigger other workflows. Use a PAT or GitHub App token in secret `RELEASE_TOKEN`. Create the secret in the GitHub UI. Never write its value to a file.

## Lockfiles
Knope updates a lockfile only if it is a listed native file (`package-lock.json`, `Cargo.lock`, `deno.lock`). It does not update `pnpm-lock.yaml`, yarn or bun lockfiles. See `lang-node.md`.

## Not verified
Pre-release label flow end to end, multi-package `CreatePullRequest` in CI, `Release` against a real repo. Dry runs and `--validate` only.
