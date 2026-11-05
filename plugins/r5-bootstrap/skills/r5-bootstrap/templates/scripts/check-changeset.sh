#!/bin/sh
set -eu
base=$1
if [ "${HEAD_REF:-}" = release ] || [ "${AUTHOR_TYPE:-}" = Bot ]; then
  exit 0
fi
if git diff --name-only --diff-filter=A "origin/$base...HEAD" -- '.changeset/*.md' | grep -qv 'README.md'; then
  exit 0
fi
echo "Add a changeset file .changeset/<name>.md. See docs/WORKFLOW.md." >&2
exit 1
