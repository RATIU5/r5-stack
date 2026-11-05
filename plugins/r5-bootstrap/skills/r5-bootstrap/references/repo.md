# Repo files

Write only what the audit marked `missing`. Replace `NAME`, `OWNER`, `REPO`. No comments in generated files.

## README
Small and generic. One sentence on what it is only when the project says so; else omit the line.
```
# NAME

One sentence on what it is.

## Develop

mise install
mise run test

## License

LICENSE_NAME
```
Drop License when there is no LICENSE, and `mise run test` when no `test` task exists.

## LICENSE
Only when the user names one: `gh api licenses/<spdx-id-lowercase> --jq .body`, with the current year and `git config user.name`.

## CODEOWNERS
`.github/CODEOWNERS`, last match wins. Solo: `* @OWNER`. Team: `* @org/team`, plus narrower lines (`/.github/`, `/scripts/`, `/mise.toml`) when a smaller group owns them. It only requests review until a ruleset requires code owner review.

## PR template
`.github/pull_request_template.md`:
```
## What and why

## Checklist
- [ ] PR title is a Conventional Commit
- [ ] Changeset added
- [ ] Tests pass
```
Drop the title and changeset lines without `knope.toml`.

## SECURITY.md
Only for a public repo, when the user wants it: `Report vulnerabilities at https://github.com/OWNER/REPO/security/advisories/new. Do not open a public issue.` Add a supported-versions line only when releases exist.

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
Node: `space`, `2`. Odin: `tab`, no `indent_size`. Otherwise copy the style of existing files or drop both indent lines. Match a formatter config when present.

## Renovate
Renovate is the only dependency updater offered, never Dependabot. Only on a yes. `renovate.json`:
```
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:recommended"],
  "semanticCommits": "enabled"
}
```
`semanticCommits` gives `chore(deps): ...` titles that pass `pr-title`. The `changeset` check skips bot PRs. The user installs the Renovate GitHub app.

## .gitignore
Always the allowlist form: copy `templates/gitignore`, add the language lines and the project's source folders. An existing file is converted as in `references/migrate.md`.
