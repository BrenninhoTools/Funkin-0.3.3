#!/usr/bin/env bash
# hmm.json pins every git dependency to an exact commit. FunkinCrew's repos (flixel, flxanimate,
# lime, ...) get rebased and force-pushed over time, so a commit that was reachable when this pin
# was made can later fall off every branch tip. `haxelib git` (which `hmm install` calls) just runs
# a plain `git clone <url> <dir>` followed by an offline `git checkout <ref>`, and a plain clone
# only fetches objects reachable from a branch or tag - so the checkout fails with
# "fatal: unable to read tree <ref>" even though the commit still physically exists on GitHub and
# can be fetched directly by its exact SHA (`git fetch origin <sha>` works even when it isn't on
# any branch).
#
# For every git dependency whose pinned commit is unreachable, this mirrors it into a local bare
# repo with that commit explicitly fetched in, then rewrites that dependency's "url" in the
# CI workspace's hmm.json (never committed) to point at the local mirror's path instead of the
# GitHub URL. A clone from a literal local path copies the whole object store - unreachable
# commits included - which is NOT true of a `file://` URL or a `git config url.insteadOf`
# rewrite (both still negotiate objects the same way a network clone would), so the mirror must
# be referenced by a plain filesystem path for this to work.
#
# Uses process substitution (< <(...)), not a pipe, to read the dependency list: piping into the
# loop would run it in a subshell, and a failure there wouldn't survive to fail this script - and
# a transient failure mirroring one dependency shouldn't stop the rest from being checked.
set -uo pipefail

mirrors="${RUNNER_TEMP:-/tmp}/hmm-mirrors"
mkdir -p "$mirrors"

failed=0

while IFS= read -r dep; do
  dep="${dep%$'\r'}" # strip a trailing \r in case jq or the input ever emits CRLF
  name=$(jq -r '.name' <<<"$dep")
  url=$(jq -r '.url' <<<"$dep")
  ref=$(jq -r '.ref' <<<"$dep")

  bare="$mirrors/$name.git"
  rm -rf "$bare"
  if ! git clone --quiet --bare "$url" "$bare"; then
    echo "::error::Could not clone $name from $url to check whether $ref is reachable"
    failed=1
    continue
  fi

  if git --git-dir="$bare" cat-file -e "$ref^{commit}" 2>/dev/null; then
    # Reachable from some branch/tag, so haxelib's normal clone will work as-is.
    rm -rf "$bare"
    continue
  fi

  echo "::warning::$name is pinned to $ref, which is no longer reachable from any branch of $url. Installing it from a local mirror instead."
  if ! git --git-dir="$bare" fetch --quiet origin "$ref"; then
    echo "::error::$name is pinned to $ref, which isn't reachable from any branch of $url, and fetching it directly by its SHA also failed - it may have been deleted upstream."
    failed=1
    continue
  fi

  jq --arg name "$name" --arg path "$bare" \
    '(.dependencies[] | select(.name == $name) | .url) = $path' \
    hmm.json > hmm.json.tmp
  mv hmm.json.tmp hmm.json
done < <(jq -c '.dependencies[] | select(.type == "git")' hmm.json)

exit "$failed"
