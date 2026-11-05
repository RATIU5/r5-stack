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
git add -A && git commit -qm "feat: init"
mise x -- knope --validate || fail "knope.toml validates"
echo "ok   knope.toml validates"

mise x -- cog install-hook commit-msg > /dev/null
echo x > f && git add f
if git commit -qm "bad message" 2> /dev/null; then fail "hook rejects a bad message"; fi
git commit -qm "feat: good message" || fail "hook accepts a good message"
echo "ok   commit-msg hook"

git commit -q --allow-empty -m 'Revert "feat: good message"' || fail "hook accepts a revert"
git commit -q --allow-empty -m "fixup! feat: good message" || fail "hook accepts a fixup"
echo "ok   revert and fixup commits"

mise tasks add lint:title --description "Check a commit or PR title" -- sh scripts/lint-commit.sh > /dev/null
mise run lint:title -- "feat: x" > /dev/null || fail "lint:title accepts a conventional title"
mise run lint:title -- "chore(deps): bump y" > /dev/null || fail "lint:title accepts a scoped title"
if mise run lint:title -- "bad title" > /dev/null 2>&1; then fail "lint:title rejects a bad title"; fi
echo "ok   lint:title"

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
mkdir -p .changeset .github/workflows dist
touch mise.toml .changeset/a.md .github/workflows/ci.yml dist/out other.txt
listed=$(git add -A -n | sed "s/^add '//; s/'$//" | sort | tr '\n' ' ')
[ "$listed" = ".changeset/a.md .github/workflows/ci.yml .gitignore mise.toml " ] || fail "gitignore allowlist: $listed"
echo "ok   gitignore allowlist"
