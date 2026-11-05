#!/bin/sh
set -eu
base=$1
if [ "${AUTHOR_TYPE:-}" = Bot ]; then
  exit 0
fi
if git diff --name-only --diff-filter=A "origin/$base...HEAD" -- '.changeset/*.md' | grep -q .; then
  exit 0
fi
if git diff --name-only "origin/$base...HEAD" -- '*CHANGELOG.md' | grep -q .; then
  exit 0
fi
echo "Add a changeset file .changeset/<name>.md or record the changelog. See docs/WORKFLOW.md." >&2
exit 1
