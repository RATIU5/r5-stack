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
HEAD_REF=release SAME_REPO=true mise run lint:changeset -- trunk > /dev/null 2>&1 || fail "release branch is exempt"
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
listed=$(git add -A -n | sed "s/^add '//; s/'$//" | LC_ALL=C sort | tr '\n' ' ')
[ "$listed" = ".changeset/a.md .github/workflows/ci.yml .gitignore AGENTS.md README.md docs/WORKFLOW.md mise.toml " ] || fail "gitignore allowlist: $listed"
echo "ok   gitignore allowlist"

cd .. && mkdir convert && cd convert && git init -q
mkdir -p src tools && touch package.json src/a.ts tools/gen.py Makefile
printf 'node_modules\ndist\n' > .gitignore
git add -A -f && git commit -qm "feat(app): init"
cp "$skill/templates/gitignore" .gitignore
git ls-files | git check-ignore --no-index --stdin | sed -E 's|^([^/]+)/.*|\1/**|' | sort -u | sed 's|^|!|' >> .gitignore
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
