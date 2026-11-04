set -eu
base=${BASE_REF:-origin/main}
map=${COMPONENTS_MAP:-scripts/components.tsv}
changed=$(git diff --name-only "$base"...HEAD)
added=$(git diff --name-only --diff-filter=A "$base"...HEAD -- .changeset)

needed=$(printf '%s\n' "$changed" | awk -F'\t' '
  NR == FNR { if ($1 ~ /^!/) skip[substr($1, 2)] = 1; else map[$1] = $2; next }
  { f = $0; ignore = 0
    for (s in skip) if (index(f, s) == 1) ignore = 1
    if (ignore) next
    for (k in map) if (k == "*" || index(f, k) == 1) { n = split(map[k], a, ","); for (i = 1; i <= n; i++) hit[a[i]] = 1 }
  }
  END { for (c in hit) print c }' "$map" - | sort)

has_record() {
  for f in $added; do
    [ -f "$f" ] || continue
    awk -v c="$1" '
      /^---[[:space:]]*$/ { fence++; next }
      fence == 1 { split($0, kv, ":"); gsub(/["'"'"' ]/, "", kv[1]); if (kv[1] == c && kv[2] ~ /(major|minor|patch)/) named = 1 }
      fence >= 2 && $0 ~ /[^[:space:]]/ { body = 1 }
      END { exit !(named && body) }' "$f" && return 0
  done
  return 1
}

status=0
for c in $needed; do
  if ! has_record "$c"; then
    echo "missing or empty changeset for component: $c" >&2
    status=1
  fi
done
exit $status
