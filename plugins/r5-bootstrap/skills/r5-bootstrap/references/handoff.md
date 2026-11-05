# Hand-off template

Print these sections in this order with real names filled in. Omit a section only when it is empty, and say so in one line. The user does every step.

## 1. Secrets
| Name | Scope | Create it |
|---|---|---|
| `RELEASE_TOKEN` | repository | Fine-grained personal access token, Contents and Pull requests write. Alternative: a GitHub App installation token minted per run with `actions/create-github-app-token`; the app then authors the release PR, so a human can approve it. |
| deploy secrets | per environment | Names read from `scripts/deploy.sh` or the `deploy` task. Each is mapped in the `deploy` step's `env:`. |

## 2. Variables
Name, scope, value. Same source as secrets.

## 3. Environments
| Environment | Required reviewers | Secrets and variables |
|---|---|---|
| `production` | the user, or the team | from sections 1 and 2 |
One row per environment from the answers.

## 4. Ruleset on BRANCH (and staging if used)
- Require a pull request. Approvals: solo 0, team 1. Team: require code owner review. Solo: leave it off, since an author cannot approve their own PR.
- Required status checks: `pr-title`, `changeset` and `check` (the jobs `ci.yml` has).
- Block force pushes and deletion. Require linear history only without a staging branch; with one, the `staging` into `BRANCH` merge needs a merge commit.
- A PAT owner cannot approve the release PR, so a team needs a second reviewer or a GitHub App token.

## 5. Repository settings
- Merge: squash. With a staging branch also allow merge commits. Automatically delete head branches. Leave auto-merge off: only a person merges.
- Squash commit message: pull request title. `pr-title` then validates what lands on `BRANCH`.
- Merge queue, if used: `ci.yml` already listens for `merge_group`.
- Public repo: enable secret scanning, push protection and private vulnerability reporting.
- Actions: workflow permissions read-only by default.
- Renovate added: install the Renovate GitHub app on the repo.

## 6. Per clone
`mise x -- cog install-hook commit-msg`.
