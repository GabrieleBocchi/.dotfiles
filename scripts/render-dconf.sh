#!/bin/sh
# Prints the keyfile for `dconf load /`: dconf/*.ini as-is, then dconf/*.ini.tmpl
# rendered at run time, so they see packages installed earlier in the apply.

set -eu

for f in "$1"/*.ini; do
    cat "$f"
    echo
done

for f in "$1"/*.ini.tmpl; do
    [ -e "$f" ] || continue
    chezmoi execute-template <"$f"
    echo
done
