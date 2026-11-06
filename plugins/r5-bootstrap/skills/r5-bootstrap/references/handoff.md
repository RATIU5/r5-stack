# Hand-off template

Print these sections in order with real names. Omit a section only when empty, and say so in one line. The user does every step.

## 1. Secrets
| Name | Scope | Create it |
|---|---|---|
| `RELEASE_TOKEN` | repository | Fine-grained personal access token, Contents and Pull requests write. Alternative: a GitHub App installation token minted per run with `actions/create-github-app-token`; the app then authors the release PR, so a person can approve it. |
| deploy secrets | per environment | Names from the `deploy` task or script, each mapped in the `deploy` step's `env:`. |

## 2. Variables
Name, scope, value. Same source as secrets.

## 3. Environments
| Environment | Required reviewers | Secrets and variables |
|---|---|---|
| `production` | the user, or the team | from sections 1 and 2 |
One row per environment.

## 4. Ruleset on BRANCH (and staging if used)
- Read existing rules (`gh api repos/OWNER/REPO/rulesets`); when one exists, word this section as changes to it.
- Require a pull request. Approvals: solo 0, team 1 plus code owner review. A solo author cannot approve their own PR.
- Required checks: `pr-title`, `changeset`, `check`, or the name of an existing job that runs the tests. Remove stale required checks (for example `commits`).
- Block force pushes and deletion. Require linear history, except with a staging branch.
- A PAT owner cannot approve the release PR: a team needs a second reviewer or the App token.

## 5. Repository settings
- Merge: squash; with a staging branch also merge commits. Squash message: pull request title. Delete head branches. Leave auto-merge off: only a person merges.
- A merge queue works: `ci.yml` listens for `merge_group`.
- Public repo: secret scanning, push protection, private vulnerability reporting.
- Actions: read-only workflow permissions by default.
- Renovate added: install the Renovate GitHub app.

## 6. Per clone
`mise x -- cog install-hook commit-msg` (`--overwrite` replaces an old hook), or the existing hook manager's install step.
