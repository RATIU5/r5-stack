set -eu
here=$(cd "$(dirname "$0")" && pwd)
skill=$here/../../plugins/r5-bootstrap/skills/r5-bootstrap
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
cd "$work"
git init -q -b trunk
git config user.email t@example.com
git config user.name t
fail() { echo "FAIL $1"; exit 1; }

echo '{"name":"app","version":"1.0.0"}' > package.json
mise use --pin cocogitto github:knope-dev/knope > /dev/null
mise lock > /dev/null
sed 's/OWNER/o/; s/REPO/r/; s/BRANCH/trunk/' "$skill/templates/knope.toml" > knope.toml
cp "$skill/templates/cog.toml" cog.toml
mkdir scripts && cp "$skill/templates/scripts/lint-commit.sh" scripts/
git add -A && git commit -qm "feat(app): init"
mise x -- knope --validate || fail "knope.toml validates"
echo "ok   knope.toml validates"

mise x -- cog install-hook commit-msg > /dev/null
echo x > f && git add f
if git commit -qm "bad message" 2> /dev/null; then fail "hook rejects a bad message"; fi
git commit -qm "feat(app): good message" || fail "hook accepts a good message"
if PATH=/usr/bin:/bin git commit -q --allow-empty -m "feat(app): no mise" 2> /dev/null; then fail "hook fails without mise"; fi
echo "ok   commit-msg hook"

git commit -q --allow-empty -m 'Revert "feat(app): good message"' || fail "hook accepts a revert"
git commit -q --allow-empty -m "fixup! feat(app): good message" || fail "hook accepts a fixup"
echo "ok   revert and fixup commits"

mise tasks add lint:title --description "Check a commit or PR title" -- sh scripts/lint-commit.sh > /dev/null
mise run lint:title -- "feat(app): x" > /dev/null || fail "lint:title accepts a conventional title"
mise run lint:title -- "chore(deps): bump y" > /dev/null || fail "lint:title accepts a scoped title"
if mise run lint:title -- "feat: no scope" > /dev/null 2>&1; then fail "lint:title requires a scope"; fi
mise run lint:title -- "feat(app)!: breaking" > /dev/null 2>&1 || fail "lint:title accepts a breaking marker"
if mise run lint:title -- "bad title" > /dev/null 2>&1; then fail "lint:title rejects a bad title"; fi
if mise run lint:title -- 'Revert "feat(app): x"' > /dev/null 2>&1; then fail "lint:title rejects a Revert title"; fi
if mise run lint:title -- "Feat: x" > /dev/null 2>&1; then fail "lint:title rejects an uppercase type"; fi
for bad in "feat: add (x): y" "fix: see (docs): later" "feat(): x" "feat(app):x" "feat(a)(b): x"; do
  if mise run lint:title -- "$bad" > /dev/null 2>&1; then fail "lint:title rejects: $bad"; fi
done
if mise run lint:title -- "feat(app): x." > /dev/null 2>&1; then fail "lint:title rejects a trailing period"; fi
if sh scripts/lint-commit.sh > /dev/null 2>&1; then fail "lint-commit.sh rejects no arguments"; fi
printf 'feat(app): x.\r\n' > crlf.msg
if sh scripts/lint-commit.sh --file crlf.msg > /dev/null 2>&1; then fail "lint-commit.sh rejects a CRLF title with a period"; fi
printf 'feat(app): x\n\nbody ends here.\n' > body.msg
sh scripts/lint-commit.sh --file body.msg > /dev/null 2>&1 || fail "lint-commit.sh checks only the first line"
if sh scripts/lint-commit.sh --file > /dev/null 2>&1; then fail "lint-commit.sh --file needs a path"; fi
echo "ok   lint:title"

mkdir scripts 2> /dev/null || true
cp "$skill/templates/scripts/check-changeset.sh" scripts/
mise tasks add lint:changeset --description "Check the PR adds a changeset" -- sh scripts/check-changeset.sh > /dev/null
git update-ref refs/remotes/origin/trunk HEAD
git checkout -q -b topic
echo y > g && git add g && git commit -qm "feat(app): more"
if mise run lint:changeset -- trunk > /dev/null 2>&1; then fail "changeset check fails without a changeset"; fi
AUTHOR_TYPE=Bot mise run lint:changeset -- trunk > /dev/null 2>&1 || fail "bot PRs are exempt"
if AUTHOR_TYPE=User mise run lint:changeset -- trunk > /dev/null 2>&1; then fail "user PRs are not exempt"; fi
mkdir -p .changeset && printf -- '---\napp: patch\n---\n\n# x\n' > .changeset/x.md && git add -A && git commit -qm "chore(app): add changeset"
mise run lint:changeset -- trunk > /dev/null 2>&1 || fail "changeset check passes with a changeset"
sh scripts/check-changeset.sh nonexist > /dev/null 2>&1 && fail "missing base fails"
[ "$(sh scripts/check-changeset.sh nonexist > /dev/null 2>&1; echo $?)" = 2 ] || fail "missing base exits 2"
if sh scripts/check-changeset.sh > /dev/null 2>&1; then fail "check-changeset.sh needs a base"; fi
git checkout -q -b rd trunk && git checkout -q topic -- scripts mise.toml
mkdir -p .changeset && printf -- '---\napp: patch\n---\n' > .changeset/README.md && git add -A && git commit -qm "docs(app): readme"
if mise run lint:changeset -- trunk > /dev/null 2>&1; then fail "a .changeset/README.md alone fails"; fi
git checkout -q -f topic
mkdir -p packages/web && echo "typo" > packages/web/CHANGELOG.md && git add -A && git commit -qm "docs(app): edit changelog"
git rm -q .changeset/x.md && git commit -qm "chore(app): drop changeset"
if mise run lint:changeset -- trunk > /dev/null 2>&1; then fail "a CHANGELOG-only edit fails"; fi
git checkout -q HEAD~1 -- .changeset/x.md && echo "## 1.0.1 (d)" > packages/web/CHANGELOG.md && git add -A && git commit -qm "docs(app): heading with pending changeset"
git rm -q .changeset/x.md && git commit -qm "chore(app): record changelog"
mise run lint:changeset -- trunk > /dev/null 2>&1 || fail "recording in the same PR passes"
git checkout -q trunk
echo "ok   changeset check"

cat > knope.toml <<'KNOPE'
[packages.app]
versioned_files = ["package.json"]
changelog = "CHANGELOG.md"

[[workflows]]
name = "prepare-release"

[[workflows.steps]]
type = "PrepareRelease"
KNOPE
mkdir .changeset
version() { sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' package.json; }
change() { printf -- '---\napp: minor\n---\n\n# %s\n' "$1" > ".changeset/$1.md"; }
change one
mise x -- knope prepare-release --prerelease-label beta > /dev/null
[ "$(version)" = "1.1.0-beta.0" ] || fail "first beta"
change two
mise x -- knope prepare-release --prerelease-label beta > /dev/null
[ "$(version)" = "1.1.0-beta.1" ] || fail "second beta"
change three
mise x -- knope prepare-release > /dev/null
[ "$(version)" = "1.1.0" ] || fail "graduate to stable"
echo "ok   pre-release flow"

mise tasks add fmt --description x -- touch fmt-ran > /dev/null
mise tasks add changelog --description x -- sh -c 'GITHUB_TOKEN="${GITHUB_TOKEN:-$(gh auth token 2>/dev/null)}" knope changelog "$@"' _ > /dev/null
mise tasks add release:publish --description x -- knope release > /dev/null
mkdir rel && cd rel && git init -q -b trunk && git config user.email t@example.com && git config user.name t
cp ../mise.toml ../mise.lock . && mise trust -q
echo '{"name":"app","version":"0.0.0"}' > package.json
sed 's/OWNER/o/; s/REPO/r/; s/BRANCH/trunk/' "$skill/templates/knope.toml" > knope.toml
mkdir .changeset && git add -A && git commit -qm "feat(app): init"
printf -- '---\napp: minor\n---\n\n# Add thing\n' > .changeset/thing.md
git add -A && git commit -qm "feat(app): add thing"
mise run changelog > /dev/null 2>&1 || fail "local changelog run"
[ -e fmt-ran ] || fail "changelog workflow runs fmt"
grep -q "^## 0.0.1" CHANGELOG.md || fail "changelog task"
[ ! -e .changeset/thing.md ] || fail "changelog run deletes the changeset"
grep -q "Add thing (\[" CHANGELOG.md || fail "changelog entry has a link"
git add -A && git commit -qm "chore(app): record changelog"
mise run -q release:publish -- --dry-run 2> /dev/null | grep -q "app/v0.0.1" || fail "release gate sees an untagged version"
git tag app/v0.0.1
[ -z "$(mise run -q release:publish -- --dry-run 2> /dev/null)" ] || fail "release gate is empty when tagged"
cd ..
echo "ok   local changelog and release gate"

mkdir ver && cd ver && git init -q -b trunk && git config user.email t@example.com && git config user.name t
echo 1.0.0 > VERSION
cat > knope.toml <<'KNOPE'
[packages.app]
versioned_files = [{ path = "VERSION", regex = '(?<version>\d+\.\d+\.\d+(?:-[0-9A-Za-z.]+)?)' }]

[[workflows]]
name = "prepare-release"

[[workflows.steps]]
type = "PrepareRelease"
KNOPE
mkdir .changeset
vchange() { printf -- '---\napp: minor\n---\n\n# %s\n' "$1" > ".changeset/$1.md"; }
vchange a; git add -A; git commit -qm init
mise x -- knope prepare-release --prerelease-label beta > /dev/null
git add -A; git commit -qm release
vchange b; mise x -- knope prepare-release --prerelease-label beta > /dev/null
git add -A; git commit -qm release
[ "$(cat VERSION)" = "1.1.0-beta.1" ] || fail "regex file keeps pre-release suffix: $(cat VERSION)"
vchange c; mise x -- knope prepare-release > /dev/null
[ "$(cat VERSION)" = "1.1.0" ] || fail "regex file graduates: $(cat VERSION)"
cd ..
echo "ok   regex version file pre-release"

mise tasks add rp --description x -- echo knope > /dev/null
[ "$(mise run rp -- --prerelease-label beta 2> /dev/null)" = "knope --prerelease-label beta" ] || fail "task args pass through"
echo "ok   task args"

mkdir ignore && cd ignore && git init -q
cp "$skill/templates/gitignore" .gitignore
mkdir -p .changeset .github/workflows dist docs
touch mise.toml .changeset/a.md .github/workflows/ci.yml dist/out other.txt docs/WORKFLOW.md README.md AGENTS.md
mkdir -p node_modules/x dist/docs .vercel
touch node_modules/x/package.json node_modules/x/README.md node_modules/x/LICENSE dist/docs/CHANGELOG.md .vercel/README.txt
listed=$(git add -A -n | sed "s/^add '//; s/'$//" | LC_ALL=C sort | tr '\n' ' ')
[ "$listed" = ".changeset/a.md .github/workflows/ci.yml .gitignore AGENTS.md README.md docs/WORKFLOW.md mise.toml " ] || fail "gitignore allowlist: $listed"
echo "ok   gitignore allowlist"

cd .. && mkdir convert && cd convert && git init -q
mkdir -p src tools dist && touch package.json src/a.ts tools/gen.py Makefile dist/gen.ts
printf 'node_modules\ndist\n' > .gitignore
git add -A -f && git commit -qm "feat(app): init"
cp "$skill/templates/gitignore" .gitignore
git ls-files | git check-ignore --no-index --stdin | grep -v / | sed 's|^|!/|' >> .gitignore
for d in $(git ls-files | git check-ignore --no-index --stdin | grep / | cut -d/ -f1 | sort -u); do git ls-files "$d" | sed -n 's/.*\.\([A-Za-z0-9]*\)$/\1/p' | sort -u | sed "s|^|!/$d/**/*.|"; done >> .gitignore
[ -z "$(git ls-files | git check-ignore --no-index --stdin || true)" ] || fail "converted allowlist hides tracked files"
touch src/new.ts; mkdir node_modules; touch node_modules/x
git add -A -n | grep -q "src/new.ts" || fail "converted allowlist shows new source files"
git add -A -n | grep -q node_modules && fail "converted allowlist ignores node_modules"
echo "ok   gitignore conversion"

mkdir -p lint/.github/workflows
for f in "$skill"/templates/workflows/*.yml; do
  sed 's/@SHA/@0123456789abcdef0123456789abcdef01234567/; s/BRANCH/main/g' "$f" > "lint/.github/workflows/$(basename "$f")"
done
(cd lint && git init -q && mise x github:rhysd/actionlint -- actionlint) || fail "actionlint on rendered workflows"
echo "ok   actionlint"
