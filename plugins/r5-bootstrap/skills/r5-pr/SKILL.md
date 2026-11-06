---
name: r5-pr
description: Create a draft pull request, or update the open one, with a title and description written from the branch's commits and diff. Runs only when the user calls it.
disable-model-invocation: true
---

# r5-pr

## Limits
- Runs only when the user calls it. Never merge. Never push. Never enable auto-merge.
- Create the PR as a draft. Offer no choice. Use `--draft` unless the user says in this request to open it live or mark it ready (`gh pr ready`).
- Edit an existing PR only after the user says yes to the shown diff.
- Write no secret and no file into the repo. Keep drafts in `mktemp`.

## Gather
1. `git status --porcelain`: uncommitted changes are not in the PR. Say so, and continue.
2. Base: the open PR's base, else `gh repo view --json defaultBranchRef`. Never assume `main`.
3. `git log BASE..HEAD` and `git diff BASE...HEAD --stat`, then read the diff.
4. `git ls-remote --exit-code --heads origin HEAD_BRANCH`. Not pushed: stop and tell the user to run `git push -u origin HEAD`.
5. `gh pr view --json number,title,body,isDraft,baseRefName`. No PR: create. A PR: update.

## Template
First found wins: `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `docs/pull_request_template.md`, `pull_request_template.md`, a single file in `.github/PULL_REQUEST_TEMPLATE/`. Several files there: ask which. None: `templates/pull_request_template.md` from this skill.

## Title
`type(scope): summary`, from the commits and the diff. Squash merge makes it the commit on the base branch. With a `lint:title` task, run `mise run lint:title -- "<title>"` and fix the title until it passes. Without one, use the types and scope rule in `docs/WORKFLOW.md`.

## Body
Fill every template section from the commits and the diff. Why before how. Leave a section blank when the diff does not answer it. Tick a checklist box only for a check you ran: `mise run lint:changeset -- BASE` for the changeset line, the project's test task for tests.

## Update
1. Read the current body.
2. Text inside `<!-- keep -->` and `<!-- /keep -->` is copied unchanged, in place.
3. Other existing text is input: carry forward what the commits still support, correct what they no longer match.
4. Show the title and a diff of the body. Wait for a yes, then `gh pr edit --title ... --body-file FILE`. A draft stays a draft.

## Create
Run `gh pr create --draft --base BASE --title ... --body-file FILE`. No confirmation step: the call is the permission. Print the PR URL.
