---
name: r5-pr
description: When the user calls it, create a draft pull request or update the open one, with a title and description written from the branch's commits and diff.
disable-model-invocation: true
---

# r5-pr

## Limits
- Never merge, push or enable auto-merge.
- Always `--draft`. Go live only when the user's request says so: omit `--draft` on create, or run `gh pr ready` on the open PR.
- Creating needs no confirmation: the call is the permission. Editing an open PR needs a yes (Update).
- Keep drafts in `mktemp` files and delete them after. Write nothing into the repo.
- Pass the title as one quoted argument to every command.

## Gather
1. `gh auth status`. `git branch --show-current`: empty is a detached HEAD. Stop on either failure and say why.
2. `git status --porcelain`: uncommitted changes are not in the PR. Say so, and continue.
3. `gh pr list --head BRANCH --state open --json number,title,body,isDraft,baseRefName`. None: create. One: update. More than one: stop and ask which.
4. Base: the PR's `baseRefName`, else `gh repo view --json defaultBranchRef`. Never assume `main`. `git fetch origin BASE`, and compare against `origin/BASE`.
5. `git log origin/BASE..HEAD` and `git diff origin/BASE...HEAD --stat`, then read the diff.
6. `git ls-remote --heads origin BRANCH` must print the sha of `git rev-parse HEAD`. Otherwise stop and tell the user to run `git push -u origin HEAD`.

## Template
First found wins: `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `docs/pull_request_template.md`, `pull_request_template.md`, a single file in `.github/PULL_REQUEST_TEMPLATE/`. Several files there: ask which. None: `templates/pull_request_template.md` from this skill, without its title and changeset lines when there is no `knope.toml`.

## Title
`type(scope): summary`, from the commits and the diff. Squash merge makes it the commit on the base branch. With a `lint:title` task, run `mise run lint:title -- "<title>"` and fix the title until it passes. Else use the rule in `docs/WORKFLOW.md`, else plain Conventional Commits.

## Body
Fill each template section from the commits and the diff, why before how. A section the diff does not answer stays blank. Tick a checklist line only for a check you ran: the title after `lint:title` passes, the changeset after `mise run lint:changeset -- origin/BASE` passes. Never tick tests: do not run them.

## Update
1. Read the current body.
2. Text inside `<!-- keep -->` and `<!-- /keep -->` is copied unchanged, in place, or at the end when the new body has no matching spot. An unclosed marker: stop and ask.
3. Other existing text is input: carry forward what the commits still support, correct what they no longer match.
4. Show the title and a diff of the body. After a yes, `gh pr edit NUMBER --title "<title>" --body-file FILE`. A draft stays a draft.

## Create
`gh pr create --draft --base BASE --title "<title>" --body-file FILE`. Print the PR URL.
