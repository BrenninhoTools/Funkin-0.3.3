#!/usr/bin/env bash
# `haxelib git` (which `hmm install` calls for every git-type dependency in hmm.json) is supposed
# to initialize a dependency's own git submodules, but the haxelib version bundled with the Haxe
# release this project pins (see HAXE_VERSION in build.yml) predates the fix for that
# (HaxeFoundation/haxelib#638, haxelib 4.2.0, Sep 2024 - after Haxe 4.3.4, Mar 2024). Lime vendors
# its native libraries (cairo, freetype, harfbuzz, SDL, openal, zlib, ...) as git submodules under
# project/lib/, so without this they're just empty directories, and rebuilding Lime's native
# libraries fails with errors like "Could not find include file lib/cairo/files.xml" - the
# manifest that lives inside the (never checked out) cairo submodule.
#
# Runs unconditionally, even when `.haxelib` was restored from cache: a cache saved from a run that
# hit this exact problem would otherwise keep re-restoring the same broken checkout forever, and
# `git submodule update --init` is a fast no-op on a submodule that's already initialized.
#
# Uses process substitution (< <(...)), not a pipe, to read the dependency list: piping into the
# loop would run it in a subshell, and a failure there wouldn't survive to fail this script.
set -uo pipefail

failed=0

while IFS= read -r name; do
  name="${name%$'\r'}" # strip a trailing \r in case jq or the input ever emits CRLF
  repo=".haxelib/$name/git"
  [ -f "$repo/.gitmodules" ] || continue

  echo "Initializing submodules for $name..."
  if ! git -C "$repo" submodule update --init --recursive --depth 1; then
    echo "::error::Failed to initialize submodules for $name"
    failed=1
  fi
done < <(jq -r '.dependencies[] | select(.type == "git") | .name' hmm.json)

exit "$failed"
