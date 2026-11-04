# Node

Checked 2026-11-04 with Node v24.21.0, pnpm 12.4.1, mise 2026.10.17. Confirm with `node --version` and `<pm> --version`. Core rules live in `core-toolchain.md`.

## Package manager
- Default to pnpm. If the project has a lockfile or `packageManager` field for another manager (npm, bun, deno), or the user names one, use that and its equivalents below.
- Pin it in `mise.toml` with `mise use --pin pnpm node@<major>`. For npm use the one that ships with Node.
- Detect from the lockfile: `pnpm-lock.yaml`, `package-lock.json`, `bun.lock`, `deno.lock`.

## Version source
`package.json` `version`, managed by Knope: `versioned_files = ["package.json"]` in `[packages.<component>]`. Never edit the version by hand.

## Lock
- Commit the lockfile.
- `package-lock.json` is a native Knope versioned file. List it beside `package.json` and Knope updates it.
- pnpm: tested with pnpm 12.4.1. Bumping the root `version` left `pnpm-lock.yaml` byte-identical and `pnpm install --frozen-lockfile` passed. No `Command` step is needed. If a bump ever changes the lock, add a `Command` step after `PrepareRelease`: `pnpm install --lockfile-only`. Knope never updates pnpm, yarn or bun lockfiles itself.
- bun, deno: not tested.

## Install in CI
1. `mise-action` runs `mise install` with `MISE_LOCKED=1`.
2. Then the clean install: `pnpm install --frozen-lockfile`, `npm ci`, `bun install --frozen-lockfile`, or `deno install --frozen`. Read `<pm> install --help` to confirm the flag.
3. Put the install in a `deps` task that `build`, `lint` and `test` depend on, so local and CI match.

## Tasks
- `mise tasks add build -- pnpm run build`, and the same for `lint`, `fmt`, `test`. Add `depends`.
- The `build` task writes the release artifact to `dist/` for `checksums`.

## Workspaces
- Each workspace package that ships is a Knope `[packages.<name>]` with its own `package.json` path. Name them like the component.
- `scripts/components.tsv` maps `packages/<name>/` to its component. List internal dependents on shared package prefixes.
- Expose a package's scripts as mise tasks with the monorepo feature (`monorepo_root = true`, `mise //packages/<name>:build`) only if the repo already uses it. Documented, not tested here.

## Deploy runners only
Shopify CLI is a deploy-runner tool, not in the mise registry. Add it with `mise use --pin npm:@shopify/cli` (listed 5.0.0 on 2026-11-04), only where the deploy task runs.
