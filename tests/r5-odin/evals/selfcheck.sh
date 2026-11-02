#!/bin/bash
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
command -v odin > /dev/null || { echo "odin is not on PATH"; exit 2; }
fails=0

report() {
  if [ "$2" = yes ]; then echo "ok   $1"; else echo "FAIL $1"; fails=$((fails + 1)); fi
}

for task in "$HERE"/tasks/*/; do
  name="$(basename "$task")"
  if [ -n "${1:-}" ] && [[ " $* " != *" $name "* ]]; then
    continue
  fi
  export EVALS="$HERE" TASK="${task%/}"
  work="$(mktemp -d)"
  cp -R "$task/setup/." "$work/"
  if (cd "$work" && bash "$task/grade.sh" > /dev/null 2>&1); then result=no; else result=yes; fi
  report "$name: the stub fails the grader" "$result"
  cp -R "$task/solution/." "$work/"
  if (cd "$work" && bash "$task/grade.sh" > /dev/null 2>&1); then result=yes; else result=no; fi
  report "$name: the reference solution passes the grader" "$result"
  rm -rf "$work"
done

[ "$fails" = 0 ]
