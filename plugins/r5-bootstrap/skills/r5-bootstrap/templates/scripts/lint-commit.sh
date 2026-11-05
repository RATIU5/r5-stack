#!/bin/sh
set -eu
if [ "$1" = --file ]; then
  msg=$(head -n1 "$2")
else
  msg=$1
fi
case $msg in
  'Revert "'*|'Merge '*|'fixup!'*|'squash!'*) exit 0 ;;
esac
if [ "$1" = --file ]; then
  exec cog verify --file "$2"
fi
exec cog verify "$msg"
