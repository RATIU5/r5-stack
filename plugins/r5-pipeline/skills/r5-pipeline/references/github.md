# GitHub

## Pin actions
Every `uses:` in a template ends in `@SHA`. For each action:
```
tag=$(gh api repos/<owner>/<repo>/releases/latest --jq .tag_name)
gh api repos/<owner>/<repo>/commits/$tag --jq .sha
```
If the repo has no releases, take the first name from `gh api repos/<owner>/<repo>/tags --jq '.[].name'`. Write `uses: <owner>/<repo>@<sha>`. Use the same SHA for repeated uses.

## Environments
Required reviewers, wait timer, deployment branch and tag rules, secrets and variables per environment. A branch or tag rule checks the ref the workflow was dispatched on, not an input, so a tag rule on `promote.yml` needs `gh workflow run promote.yml -r <tag>`. Secrets reach a job only after the rules pass. Private repos need a paid plan for these rules.

## Rulesets
Required status checks, required pull requests, restricted tag creation. A commit message pattern rule is the server-side Conventional Commits check.

## CODEOWNERS
`.github/CODEOWNERS`, last match wins. Cover `.github/` and `scripts/`.

## Dispatch
`gh workflow run <file> -f key=value`. Pass inputs to `run:` through `env:`, never by interpolating `${{ inputs.x }}` into the script.

## Attestation
`actions/attest` with `subject-path`, permissions `id-token: write`, `attestations: write`, `contents: read`. Verify a file with `gh attestation verify <file> --repo <owner>/<repo>`.
