# GitHub features

Checked 2026-11-04 against docs.github.com, gh 2.103.2. Plan limits change: confirm in the repository settings.

## Read help first
`gh --help`, `gh workflow run --help`, `gh release download --help`, `gh attestation verify --help`.

## Environments
- Required reviewers (one approval is enough), wait timer, deployment branch and tag rules, secrets and variables scoped to the environment.
- Private repos need GitHub Team or Pro for these rules. On Free they are ignored.
- Secrets reach a job only after the rules pass.
- A job can pick its environment from an input: `environment: ${{ inputs.environment }}`. The rules of the chosen environment still apply.
- Tag rule `*/v*` for `production`: pattern support not verified. Create the rule, then test with a dispatch to a non-matching ref.

## Rulesets
- Rules: required status checks, restrict creation/update/deletion (also for tags), required linear history, tag rulesets.
- A commit message pattern rule (regex, `(?m)` for multiline) is the server-side Conventional Commits check. Plan availability not verified.
- Create rulesets in the UI. The task does not store them in files.

## CODEOWNERS
Path `.github/CODEOWNERS`. Gitignore-style patterns, owners `@user` or `@org/team`, last match wins, owner needs write access. Must exist on the base branch.

## Reusable workflows
- Add `on: workflow_call` with `inputs` and `secrets`. Call at job level: `uses: <owner>/<repo>/.github/workflows/<file>@<full SHA>`.
- Nesting is limited to ten levels. SHA pinning is the documented safest option.
- Call count and input limits: not verified.

## workflow_dispatch
- Input types: string, choice, boolean, number, environment. At most 25 inputs.
- Trigger: `gh workflow run <file> -f key=value` (`-f` raw string, `-F` respects `@file`, `--json` from stdin, `-r` ref, `-R` repo).
- Pass inputs to `run:` through `env:`, never by interpolating `${{ inputs.x }}` into the script.

## Attestations
- `actions/attest-build-provenance` v4 is a wrapper. Its README says to use `actions/attest`. Templates use `actions/attest` v4.2.2.
- Inputs seen in `action.yml`: `subject-path`, `subject-digest`, `subject-name`, `subject-checksums`, `predicate-type`, `push-to-registry`.
- Permissions: `id-token: write`, `attestations: write`, `contents: read`.
- Verify: `gh attestation verify <file> --repo <owner>/<repo>`. Attest the `SHA256SUMS` file, then check each artifact against it.

## Actions pinned in templates
| Action | Tag | SHA |
|---|---|---|
| actions/checkout | v7.0.1 | 3d3c42e5aac5ba805825da76410c181273ba90b1 |
| jdx/mise-action | v5.2.6 | f5be966e4a917d54244728e6a5fdcd1d93a35e6c |
| actions/attest | v4.2.2 | 1e69f48acb82d1966a394da916b4c1698aa569d6 |
| actions/upload-artifact | v7.0.2 | cf430e030ddbb5b0abf93d22962f4752f3646cd9 |
| actions/download-artifact | v8.0.2 | 9000827ccba6bdab643e8b6fd33ac0654aef8333 |
Re-resolve SHAs with `gh api repos/<owner>/<repo>/git/ref/tags/<tag>` before copying. Update the table when you change a pin.

## Preview per PR by storefront host
- Shopify Oxygen (Hydrogen): each push gets a preview deployment, optional PR comment with the link. Strictly per PR: not verified.
- Shopify theme: `shopify theme push --unpublished` creates a preview theme. Not verified against current docs. Per-PR cleanup is yours to build.
- Cloudflare Pages: one preview URL per PR from same-repo branches, public unless protected with Access.
- Vercel: preview on push or PR by default. Custom environments need Pro.
- Netlify: Deploy Previews exist. Defaults and limits not verified.
