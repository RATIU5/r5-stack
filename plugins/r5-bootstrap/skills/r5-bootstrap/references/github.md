# GitHub

## Pin actions
Every `uses:` in a template ends in `@SHA`. Per action:
```
tag=$(gh api repos/<owner>/<repo>/releases/latest --jq .tag_name)
gh api repos/<owner>/<repo>/commits/$tag --jq .sha
```
No releases: take the highest of `gh api repos/<owner>/<repo>/tags --paginate --jq '.[].name' | sort -V | tail -1`. Write `uses: <owner>/<repo>@<sha>`. Reuse one SHA for repeated uses, and reuse the SHA a repo already pins.

## Environments
Required reviewers, wait timer, deployment branch and tag rules, secrets and variables per environment. A rule checks the ref the workflow was dispatched on, not an input, so a tag rule on `promote.yml` needs `gh workflow run promote.yml -r <tag>`. Secrets reach a job only after the rules pass. Private repos need a paid plan for these rules.

## Rulesets
Required status checks and pull requests. Leave tag creation unrestricted: the release job tags with `GITHUB_TOKEN`. Commit message pattern rules need Enterprise Cloud and see only the squash commit, so the `pr-title` job is the Conventional Commits check.

## Dispatch and event text
`gh workflow run <file> -f key=value`. Pass inputs, PR titles and other event text to `run:` through `env:`, never by interpolating `${{ ... }}` into the script.

## Attestation
`actions/attest` with `subject-path` and permissions `id-token: write`, `attestations: write`, `contents: read`. Verify with `gh attestation verify <file> --repo <owner>/<repo>`. Private and internal repos need Enterprise Cloud.
