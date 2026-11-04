---
name: r5-pipeline
description: Set up and run the shared release and CI/CD toolchain (mise, Knope, cocogitto, GitHub Actions) so every r5 project uses the same tools, commands and file layout, with Node and Odin references.
---

# r5-pipeline

Tool versions and check dates are in `references/verified.md`. Confirm the installed version with `<tool> --version` before relying on any reference.

## First
- Read `${CLAUDE_PLUGIN_ROOT}/rules/core.md` if the session did not inject it.
- Read what exists before writing: `mise.toml`, `mise.lock`, `knope.toml`, `cog.toml`, `.changeset/`, `scripts/`, `.github/workflows/`. Existing files win over templates.
- Use the project's tool, not a global one: `mise x -- <tool>` or `mise run <task>`.

## CLI first
- Before using a tool, read `<tool> --help`, then `<tool> <subcommand> --help` for each subcommand you plan to use.
- Create and change files with the tool: `mise use --pin`, `mise lock`, `mise tasks add`, `mise generate`, `knope --generate`, `knope document-change`, `cog init`.
- Run the command, then review its output. Never hand-write a file a CLI can generate.
- Copy from `templates/` only when no command produces the file. Say so, and review the copy against the current `--help`.
- Do not paste subcommand lists into project docs. Point to `--help`.

## Rules
- Every repeatable command is a mise task. Local and CI run the same `mise run <task>`.
- Pin exact tool versions in `mise.toml`, commit `mise.lock`, install in CI with `MISE_LOCKED=1`.
- Each user-facing PR adds a Knope changeset in `.changeset/`. The `gate` task fails without one.
- Tags are `<component>/vX.Y.Z`. Use `[packages.<component>]` in `knope.toml`, never `[package]`.
- Build once. Promotion and rollback deploy the same artifact after its checksum is verified.
- Trunk-based: everything merges to `main`. Environments replace long-lived branches.
- A script longer than 3 lines, or with more than 3 `&`, goes in `scripts/` and mise calls it. Every tool a script needs is in `mise.toml`.
- No comments in generated or templated files. Explanations live in these references.
- Never run a release, deploy or promotion. Never push or open a PR. Never store a secret in a file.

## References (read one)
- `references/core-toolchain.md`: the pipeline end to end, gate checks, environments, monorepo, many-repo, out of scope.
- `references/tools-mise.md`: mise tools, lock, tasks, github backend, plugins, mise-action.
- `references/tools-knope.md`: Knope config, changesets, workflows, release PR flow, limits.
- `references/tools-github.md`: environments, rulesets, CODEOWNERS, reusable workflows, dispatch, attestations, previews.
- `references/lang-node.md`: Node and package manager rules.
- `references/lang-odin.md`: Odin version file, compiler, deps lock, runners.
- `references/verified.md`: versions checked, dates, and open items.

## Templates (`templates/`)
`mise.toml`, `knope.toml`, `components.tsv`, `gate-task.sh` (install as `scripts/gate.sh`), `deps.lock`, `deps-verify.sh`, `version-generate.sh`, `workflows/{ci,prepare-release,release,promote}.yml`.
