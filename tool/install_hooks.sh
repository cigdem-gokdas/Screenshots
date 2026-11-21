#!/usr/bin/env bash
set -eu
root=$(git rev-parse --show-toplevel)
mkdir -p "$root/.git/hooks"
cp "$root/tool/pre-commit" "$root/.git/hooks/pre-commit"
chmod +x "$root/.git/hooks/pre-commit"
echo "Installed pre-commit hook."
