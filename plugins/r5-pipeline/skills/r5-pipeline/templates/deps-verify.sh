set -eu
status=0
while read -r name url rev sum path; do
  got=$(cd "$path" && find . -type f -not -path './.git/*' | LC_ALL=C sort | xargs shasum -a 256 | shasum -a 256 | cut -d' ' -f1)
  if [ "$got" != "$sum" ]; then
    echo "hash mismatch: $name ($path) expected $sum got $got" >&2
    status=1
  fi
done < deps.lock
exit $status
