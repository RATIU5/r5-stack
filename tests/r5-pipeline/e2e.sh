set -eu
here=$(cd "$(dirname "$0")" && pwd)
skill=$here/../../plugins/r5-pipeline/skills/r5-pipeline
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
git add -A && git commit -qm "feat: init"
mise x -- knope --validate || fail "knope.toml validates"
echo "ok   knope.toml validates"

mise x -- cog install-hook commit-msg > /dev/null
echo x > f && git add f
if git commit -qm "bad message" 2> /dev/null; then fail "hook rejects a bad message"; fi
git commit -qm "feat: good message" || fail "hook accepts a good message"
echo "ok   commit-msg hook"

mise tasks add lint:commits --description "Check commit messages" -- cog check --ignore-merge-commits > /dev/null
mise run lint:commits -- HEAD~1..HEAD || fail "lint:commits runs"
echo "ok   lint:commits"

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
