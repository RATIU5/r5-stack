#!/bin/bash
set -u
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN="$REPO/plugins/r5-odin"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
fails=0

ask() {
  (cd "$WORK" && claude -p "$1" --model sonnet --effort medium --plugin-dir "$PLUGIN" --allowedTools "$2" --output-format stream-json --verbose 2>/dev/null)
}

report() {
  if [ "$2" = yes ]; then echo "ok   $1"; else echo "FAIL $1"; fails=$((fails + 1)); fi
}

contains() {
  if printf '%s' "$1" | grep -qF -- "$2"; then echo yes; else echo no; fi
}

git -C "$WORK" init -q
printf 'package main\n\nx := 1\n' > "$WORK/a.odin"

out=$(ask "Run exactly this Bash command and report its result: git commit --allow-empty -m test" "Bash(git:*)")
report "git commit is denied" "$(contains "$out" "r5-odin: git commit is blocked")"
report "no commit was made" "$([ "$(git -C "$WORK" rev-list --all --count 2>/dev/null)" = 0 ] && echo yes || echo no)"

out=$(ask "Run exactly this Bash command and report its result: git pull" "Bash(git:*)")
report "git pull is denied" "$(contains "$out" "r5-odin: git pull is blocked")"

out=$(ask "Use the Edit tool once to replace 'x := 1' with 'x := 1 // one' in a.odin." "Edit")
report "comment edit is denied" "$(contains "$out" "new comment lines")"
report "file unchanged after denied edit" "$(grep -q '//' "$WORK/a.odin" && echo no || echo yes)"

out=$(ask "Use the Edit tool once to replace 'x := 1' with 'x := 2' in a.odin." "Edit")
report "plain edit is allowed" "$(grep -q 'x := 2' "$WORK/a.odin" && echo yes || echo no)"

out=$(ask "Use the Agent tool exactly once with subagent_type r5-odin:odin-coder, model fable and prompt 'hi'. Report the tool result verbatim." "Agent")
report "fable agent call is denied" "$(contains "$out" "the fable model is never allowed")"

out=$(ask "Run exactly this Bash command and report its output, without changing it: cat <<'EOF'
\`git commit\` is only text
EOF" "Bash(cat:*)")
report "quoted git text in a heredoc is allowed" "$(contains "$out" "is only text")"

[ "$fails" = 0 ]
