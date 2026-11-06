# Node, Bun, Deno, Cloudflare Workers

## Pick the runtime and package manager
Use what the project already has. Otherwise ask, defaulting to Node with pnpm. Pin Node with `node@lts`, or the version in `engines` or `.nvmrc`, never the bare latest.

| Signal | mise tool | Install in CI | Version file |
|---|---|---|---|
| `pnpm-lock.yaml`, or default | `node`, `pnpm` | `pnpm install --frozen-lockfile` | `package.json` |
| `package-lock.json` | `node` | `npm ci` | `package.json`, `package-lock.json` |
| `bun.lock` | `bun` | `bun install --frozen-lockfile` | `package.json` |
| `deno.json` | `deno` | `deno install --frozen` | `deno.json` |

Cloudflare Workers (`wrangler.toml`, `wrangler.json` or `wrangler.jsonc`) use the row of their package manager. `wrangler` is a project dependency, so `deploy` runs it through the package manager (`pnpm exec wrangler deploy`, `npx wrangler deploy`, `bunx wrangler deploy`).

No lockfile: the frozen install fails. Ask the user to run `<pm> install` once and commit the lockfile.

When `package.json` has `packageManager`, pin that exact version (`mise use --pin pnpm@<version>`) so the frozen install matches the lockfile.

## .gitignore allowlist
Add anchored lines: `!/package.json`, `!/pnpm-lock.yaml` (or `!/package-lock.json`, `!/bun.lock`, `!/deno.json`), `!/tsconfig*.json`, `!/src/**`, and each source folder the project has.

## Tasks
- `deps` runs the install above, with `sources`, `outputs` (`references/pipeline.md`). `build`, `lint`, `test`, `fmt` depend on `deps` and call the package manager's `run` for the scripts `package.json` has. Add only scripts that exist.
- `build` writes the release artifact to `dist/`.
- To reach any other package.json script through mise, add the `pkg` task from `mise.md`.

## Versions
Knope owns the version: `versioned_files = ["package.json"]`, plus `package-lock.json` for npm. Add `"version": "1.0.0"` when `package.json` has none. Never edit a version by hand. Bumping the root version leaves `pnpm-lock.yaml` and `bun.lock` valid for the frozen installs above.

## Workspaces
One `[packages.<name>]` per workspace package that ships, with that package's `package.json`. Add `dev:<name>` tasks for packages that exist (`<pm> --filter <name> run dev` for pnpm).

## Deploy secrets
Name them for the user's hand-off: Workers use `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`.

## oxc toolchain (JavaScript and TypeScript)
Defaults for Node projects: `oxlint` for `lint`, `oxfmt` for `fmt`. oxc does not type-check, so a TypeScript project also gets `tsc --noEmit` in `lint`. Add them as dev dependencies with the package manager, never globally. Run `<pm> exec oxlint --help` and `<pm> exec oxfmt --help` (or `pnpm dlx`, `npx`) before writing scripts, and use the flags they print. A project already on another linter or formatter keeps it. Add a `test` task only when the project has a test runner.
