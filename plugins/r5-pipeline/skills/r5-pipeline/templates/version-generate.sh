set -eu
version_file=$1
out=$2
pkg=$3
want=$(printf 'package %s\n\nVERSION :: "%s"\n' "$pkg" "$(tr -d '[:space:]' < "$version_file")")
if [ "${4:-}" = "--check" ]; then
  [ "$(cat "$out")" = "$want" ] || { echo "stale: $out" >&2; exit 1; }
else
  printf '%s\n' "$want" > "$out"
fi
