#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="$(cd "$HERE/../../.." && pwd)"
MODE="${1:-with}"
TRIALS="${2:-1}"
ONLY="${3:-}"
command -v odin > /dev/null || { echo "odin is not on PATH"; exit 2; }
command -v claude > /dev/null || { echo "claude is not on PATH"; exit 2; }

plugin_args=()
case "$MODE" in
  with) plugin_args=(--plugin-dir "$REPO/plugins/r5-odin") ;;
  without) ;;
  none) plugin_args=(--disallowedTools "Skill(odin)") ;;
  *) echo "mode must be with, without or none"; exit 2 ;;
esac

passes=0
total=0
for task in "$HERE"/tasks/*/; do
  name="$(basename "$task")"
  export EVALS="$HERE" TASK="${task%/}"
  if [ -n "$ONLY" ] && [[ " $ONLY " != *" $name "* ]]; then
    continue
  fi
  for trial in $(seq "$TRIALS"); do
    work="$(mktemp -d)"
    cp -R "$task/setup/." "$work/"
    (cd "$work" && claude -p "$(cat "$task/prompt.txt")" --model sonnet --effort medium ${plugin_args[@]+"${plugin_args[@]}"} --permission-mode acceptEdits --allowedTools "Bash(odin:*)" "Bash(cc:*)" "Bash(ar:*)" "Bash(ls:*)" "Bash(cat:*)" > "$work/.claude-out.txt" 2>&1)
    if (cd "$work" && bash "$task/grade.sh" > "$work/.grade-out.txt" 2>&1); then
      result=pass
      passes=$((passes + 1))
    else
      result=FAIL
    fi
    total=$((total + 1))
    printf '%s\t%s\t%s\t%s\n' "$MODE" "$name" "$trial" "$result"
    if [ "${KEEP:-0}" = 1 ] || [ "$result" = FAIL ]; then echo "kept $work"; else rm -rf "$work"; fi
  done
done
echo "$MODE: $passes/$total passed"
