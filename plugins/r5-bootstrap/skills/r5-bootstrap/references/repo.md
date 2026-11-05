# Repo files

Write only what the audit marked `missing`. Replace `NAME`, `OWNER`, `REPO`. No comments in generated files.

## README
A very small generic one. Fill in one sentence only when the project says what it is, else leave the line out.
```
# NAME

One sentence on what it is.

## Develop

mise install
mise run test

## License

LICENSE_NAME
```
Drop the License section when there is no LICENSE. Drop test when no `test` task exists.

## LICENSE
Only when the user names one. Fetch the text with `gh api licenses/<spdx-id-lowercase> --jq .body`, replace the year and holder with the current year and `git config user.name`. Never pick one silently.

## CODEOWNERS
`.github/CODEOWNERS`, last match wins.
- Solo: `* @OWNER`.
- Team: `* @org/team`, and `/.github/ @org/team`, `/mise.toml @org/team` when a narrower group should own them.
It only requests review until a ruleset requires code owner review.

## PR template
`.github/pull_request_template.md`:
```
## What and why

## Checklist
- [ ] Changeset added for user-facing changes
- [ ] Tests pass
```
Drop the changeset line when the repo has no `knope.toml`.

## SECURITY.md
Only for a public repo, and only if the user wants it. Point to GitHub private vulnerability reporting: `Report vulnerabilities at https://github.com/OWNER/REPO/security/advisories/new. Do not open a public issue.` Add the supported versions line only when the project has releases.

## .editorconfig
```
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = INDENT
indent_size = SIZE
```
Node: `space`, `2`. Odin: `tab`, drop `indent_size`. Other languages: take the style from existing files, else drop both indent lines. Match the formatter's config when one exists.

## Renovate
Only when the user says yes. `renovate.json`:
```
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "semanticCommits": "enabled"
}
```
`semanticCommits` gives `chore(deps): ...` titles, which pass `pr-title`. The user installs the Renovate GitHub app (hand-off).

## .gitignore
No `.gitignore`: copy `templates/gitignore` and add the project's source paths.
