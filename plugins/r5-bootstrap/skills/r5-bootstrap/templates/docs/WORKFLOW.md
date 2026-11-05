# Workflow

How to commit, open a PR and release. Humans and agents follow the same rules. The checks below enforce them.

## Rules
1. Branch from `BRANCH`. Open a PR. Never push to `BRANCH`.
2. Write Conventional Commit messages: `type(scope): summary`.
3. Title the PR the same way. The PR title becomes the squash commit on `BRANCH`.
4. Every PR adds one changeset file.
5. Merge the release PR to ship. Never tag or publish by hand.
6. Only a person merges a PR. Agents never merge and never enable auto-merge.

## Commits
- Format: `type(scope): summary`. Scope is required: the component or area, such as `api`, `ci`, `docs` or `deps`. Add `!` before the colon for a breaking change.
- Types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- Lowercase type, imperative summary, no trailing period.
- The commit-msg hook checks each local commit. Install it once per clone: `mise x -- cog install-hook commit-msg`.
- Never commit with `--no-verify`. CI checks the PR title either way.
- Revert with a title like `revert(api): add x`.

## Pull requests
- Title: same format as a commit. CI labels the PR with its type.
- Small and focused: one concern per PR.
- Fill in the PR template. Squash merge only.
- PRs with no activity for 45 days are closed after a warning. Add the `keep-open` label to stop that.
- Workflows on pull requests never get secrets. Do not add any.

## Changesets
A changeset is a file `.changeset/<short-name>.md`. Every PR from a person or an agent needs one. PRs created by bots or apps (Renovate) and the release PR do not. Pending changesets are the unreleased changes. The release PR turns them into the next version heading in `CHANGELOG.md` and deletes them.
```
---
app: minor
---

# Add the thing
```
- Use one line per component: `<component>: <type>`.
- Types: `major`, `minor`, `patch` bump the version. `docs` and `chore` get their own changelog section and bump the patch version.
- The commit or PR type never changes the version. Only the changeset does.
- Below 1.0.0 a `minor` change bumps the patch number.
- The title line is the changelog entry. Write it for a user, not a developer.
- Keep only changeset files in `.changeset/`.

## Checks
| Check | Enforces | Run locally |
|---|---|---|
| `pr-title` | PR title is a Conventional Commit (the release PR is exempt) | `mise run lint:title -- "feat(api): x"` |
| `changeset` | PR adds a changeset (bot, app and release PRs are exempt) | `mise run lint:changeset -- BRANCH` |
| `check` | lint and tests pass | `mise run lint`, `mise run test` |
| commit-msg hook | each local commit message | runs on `git commit` |

Required checks are set in the repository ruleset. A red check blocks the merge.

## Release
1. Changes merge to `BRANCH`. A bot opens or updates one release PR with versions and the changelog.
2. Review the version bump and the changelog. Merge the release PR.
3. CI builds, attests, tags `<component>/vX.Y.Z` and creates the GitHub release.
4. Pre-release: run the `prepare-release` workflow with `alpha`, `beta` or `rc`. Merge or close an open pre-release PR before merging other PRs.
5. Fix a bad release by merging a new fix PR and releasing forward. There are no support branches.

## Setup
- `mise install` installs the pinned tools.
- `mise tasks` lists every task.
- Run the hook install from Commits once per clone.

## When a check fails
- `pr-title`: edit the PR title. The check reruns on edit.
- `changeset`: add `.changeset/<name>.md`, then push.
- Hook rejects a message: fix it, commit again. Do not bypass it.
