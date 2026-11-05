# mise

## Commands
- `mise use --pin <tool>...`: install and write exact pins. Knope: `github:knope-dev/knope`. Cocogitto: `cocogitto` (binary `cog`). Check names with `mise registry <name>`.
- `mise lock`: write `mise.lock`. Commit it. `MISE_LOCKED=1` makes installs fail instead of resolving.
- `mise tasks add <name> --description "..." -- <command>`: add a task. `--depends <task>` adds a dependency. Review the generated entry.
- `mise run <task> -- <args>`: extra args append to the task command.
- `mise x -- <cmd>`: run with the project's tools.

## Pipeline tasks
```
mise tasks add lint:title --description "Check a commit or PR title" -- sh scripts/lint-commit.sh
mise tasks add release:prepare --description "Open or refresh the release pull request" -- knope prepare-release
mise tasks add release:publish --description "Create tags and GitHub releases" -- knope release
```
Check a title with `mise run lint:title -- "feat: x"`. Task names with `:` are quoted in TOML. Do not add a task for work done once, such as installing the commit hook.

## Tasks
- Only project-wide tasks live in `mise.toml`. Developers decide whether finer commands live in mise, scripts or the language's own manifest.
- A task that forwards to a script runner takes arguments through `usage`:
```
[tasks.pkg]
description = "Run a package.json script"
usage = '''
arg "<script>"
arg "[args]" var=#true
'''
run = 'pnpm run $usage_script $usage_args'
```
  Use the project's package manager in `run`. For npm write `npm run $usage_script -- $usage_args`.

## github backend
`"github:owner/repo"` in `[tools]`. Options: `asset_pattern`, `version_prefix`, `bin_path`, `rename_exe`, `checksum`, `platforms.<os>-<arch>`. `mise lock` records checksums for it.

## mise-action
Pin by SHA. It installs from `mise.lock` when present. It has no `locked` input, so set `MISE_LOCKED` in workflow `env`.
