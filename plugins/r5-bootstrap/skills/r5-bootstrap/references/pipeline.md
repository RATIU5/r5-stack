# Pipeline

## Flow
1. A PR carries code and a changeset. `ci.yml` runs `pr-title` (the squash message), `changeset` and `check` (`lint`, `test`). `label-pr.yml` labels it by title type. Every title needs a scope. Local commits may be `Revert "..."`, merge, fixup or squash!; PR titles may not (`revert(scope): ...`).
2. `changeset` passes a PR that adds a changeset or changes a `CHANGELOG.md`, and exempts PRs created by bots or apps (Renovate). A person, or an agent acting as one, needs one of the two.
3. Merge to `BRANCH`. `prepare-release.yml` opens or refreshes one release PR (versions, changelog, changesets removed). A push with no changesets skips it.
4. Merge the release PR. `release.yml` runs on every push to `BRANCH`; when a version has no tag (`release:publish --dry-run` prints something) it builds, attests `dist/*`, and `release:publish` tags and creates the GitHub releases with the assets. A version recorded locally with `mise run changelog` in a feature PR is released the same way.
5. `promote.yml` (manual) deploys a tag to an environment. Rollback is the same run with an older tag.

Trunk-based. The only long-lived branch is the optional `staging`.

## Artifacts
- `build` writes files to `dist/`. For a directory tree, build into another folder and archive it (`tar -czf dist/<component>.tgz -C <outdir> .`); archiving a folder into itself fails.
- Release assets are `dist/<component>*`. Attestation covers `dist/*`. Promotion downloads the tag's assets.
- A component with nothing to ship (a library published as a tag), or a private repo without Enterprise Cloud (`references/github.md`), drops `assets` in `knope.toml`, the build and attest steps in `release.yml`, and the download and verify steps in `promote.yml`.
- Hosts that build from source (Cloudflare Workers, Hydrogen, Oxygen) cannot deploy the archive; `deploy` builds from the checked-out tag. Tell the user the attestation covers the assets, not that deploy.

## Environments
Default `production`; others from the user. Each is a GitHub Environment with its own secrets and variables. `promote.yml` takes the environment as input, so adding one changes no workflow. `deploy` is a mise task reading `TARGET` and `TAG` (and `COMPONENT` when promoting); over 3 lines it lives in `scripts/deploy.sh`.

## Staging branch
For changes that need load testing before production (storefronts).
- Feature PRs target `staging`; a push runs `staging.yml`, which deploys to the `staging` environment.
- Passing staging merges into `BRANCH` by PR with a merge commit, not squash. After each release PR merges, `BRANCH` goes back into `staging` the same way. The ruleset cannot require linear history.
- Production deploys the artifact built on `BRANCH`, not the staging build.

## Pre-releases
Dispatch `prepare-release.yml` with `alpha`, `beta` or `rc`; Knope numbers `1.1.0-beta.0`, `1.1.0-beta.1`. Pre-releases keep the changesets; the stable run deletes them. Dispatch with `none` to publish the stable version. Promote a pre-release tag only to a non-production environment. A label applies to one run, so dispatch again after each merge. Merge or close an open pre-release PR before merging other PRs, or the next push replaces it with a stable release PR.

## Fixes and rollback
Roll forward with a fix PR and a normal release. Roll back with `promote.yml` and an older tag. There are no support branches: the release workflows run only on `BRANCH`.

## Monorepo
One `[packages.<name>]` per shippable component, each with its own `versioned_files` and `changelog`; a changeset names every component it affects. Per-component tasks (`dev:<name>`, `build:<name>`) only for components that exist. Artifacts in `dist/` are named by component.

## Other languages
Find tools with `mise registry <name>`. Pick `versioned_files` from the native list in `knope.md` or a regex entry. Add `build`, `lint`, `test` tasks that call the language's CLI, depending on a `deps` task that installs with the frozen or locked flag.
