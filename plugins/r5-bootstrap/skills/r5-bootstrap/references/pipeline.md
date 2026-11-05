# Pipeline

## Flow
1. A dev opens a PR with code and a changeset (`knope document-change`). `ci.yml` runs `pr-title` (the squash message) and `check` (`lint`, `test`). Revert, merge, fixup and squash! titles pass the title check.
2. Merge to `BRANCH`. `prepare-release.yml` opens or refreshes one release PR: versions, changelog, changesets removed. A push with no changesets skips the step.
3. Merge the release PR. `release.yml` builds, attests `dist/*`, and `release:publish` creates tags and GitHub releases with the assets.
4. `promote.yml` (manual) deploys a tag to an environment. Rollback is the same run with an older tag.

Trunk-based: no long-lived branches except the optional `staging` branch.

## Artifacts
- `build` leaves only files in `dist/`, one per component or more. When the output is a directory tree, end `build` by archiving it (`tar -czf dist/<component>.tgz -C <outdir> .`).
- Release assets use `dist/<component>*` per component. Attestation covers `dist/*`. Promotion downloads the tag's assets.
- A component with nothing to ship (a library published as a tag only), or a private repo without GitHub Enterprise Cloud (attestation needs it), drops `assets` in `knope.toml`, the build and attest steps in `release.yml`, and the download and verify steps in `promote.yml`.
- Hosts that build from source (Cloudflare Workers, Hydrogen and Oxygen) cannot deploy the archive. `deploy` then builds from the checked-out tag. Tell the user the attestation covers the release assets, not that deploy.

## Environments
Take them from the user. Default `production`. Each is a GitHub Environment holding its own secrets and variables. `promote.yml` takes the environment as input, so adding one needs no workflow change. Add `deploy` as a mise task that reads `TARGET` and `TAG` from the environment, and `COMPONENT` when promoting. Put it in `scripts/deploy.sh` when it is longer than 3 lines.

## Staging branch
Use when the user wants changes load tested before production (storefronts).
- Feature PRs target `staging`. Push to `staging` runs `staging.yml`, which deploys to the `staging` environment.
- When staging passes, open a PR `staging` into `BRANCH` and merge it with a merge commit, not squash, so history matches. Releases then run as in Flow. The ruleset then cannot require linear history.
- Keep `staging` current: after each release PR merges, open a PR `BRANCH` into `staging` and merge it with a merge commit.
- Production deploys the release artifact built on `BRANCH`, not the staging build.

## Pre-releases
Dispatch `prepare-release.yml` with `alpha`, `beta` or `rc`. Knope numbers them `1.1.0-beta.0`, `1.1.0-beta.1`. A pre-release keeps the changesets; only the stable run deletes them. Dispatch with no label to publish the stable version. Promote a pre-release tag to a non-production environment. A label applies to one run: the next push to `BRANCH` prepares a stable release again, so dispatch with the label after each merge.

## Monorepo
- One `[packages.<name>]` per shippable component, each with its own `versioned_files` and `changelog`. A changeset names each component it affects.
- Add per-component tasks (`dev:<name>`, `build:<name>`) only for components that exist now.
- `build` writes every artifact to `dist/`, named by component.

## Other languages
For a language without a reference: find tools with `mise registry <name>`, pick `versioned_files` from the native list in `knope.md` or use a regex entry, and add `build`, `lint`, `test` tasks that call the language's own CLI. Install dependencies in a `deps` task that `build`, `lint` and `test` depend on, using the frozen or locked install flag.
