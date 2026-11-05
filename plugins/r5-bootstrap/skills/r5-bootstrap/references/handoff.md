# Hand-off template

Print these sections in this order with real names filled in. Omit a section only when it is empty, and say so in one line. The user does every step.

## 1. Secrets
| Name | Scope | Create it |
|---|---|---|
| `RELEASE_TOKEN` | repository | Fine-grained personal access token, Contents and Pull requests write. GitHub App tokens expire after an hour and do not work. |
| deploy secrets | per environment | Names read from `scripts/deploy.sh` or the `deploy` task. |

## 2. Variables
Name, scope, value. Same source as secrets.

## 3. Environments
| Environment | Required reviewers | Secrets and variables |
|---|---|---|
| `production` | the user, or the team | from sections 1 and 2 |
One row per environment from the answers.

## 4. Ruleset on BRANCH (and staging if used)
- Require a pull request. Approvals: solo 0, team 1. Team: require code owner review. Solo: leave it off, since an author cannot approve their own PR.
- Required status checks: the job names in `ci.yml` (commits, lint, test, build where those jobs exist).
- Block force pushes and deletion. Require linear history.
- The `RELEASE_TOKEN` owner cannot approve the release PR, so a team needs a second reviewer.

## 5. Repository settings
- Merge: squash only. Automatically delete head branches.
- Public repo: enable secret scanning, push protection and private vulnerability reporting.
- Actions: workflow permissions read-only by default.

## 6. Per clone
`mise x -- cog install-hook commit-msg`.
