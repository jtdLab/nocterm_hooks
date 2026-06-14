#!/usr/bin/env bash
# Publish nocterm_hooks to pub.dev from your local machine.
#
# Prerequisites:
#   - dart on PATH
#   - pub.dev credentials: run `dart pub token add https://pub.dev` once
#
# Usage:
#   ./tool/publish.sh          # dry-run + interactive publish
#   ./tool/publish.sh --dry-run

set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

dry_run=false
if [[ "${1:-}" == "--dry-run" ]]; then
  dry_run=true
fi

version="$(grep '^version:' pubspec.yaml | awk '{print $2}')"
echo "==> nocterm_hooks $version"

echo "==> dart analyze"
dart analyze

echo "==> dart test"
dart test

echo "==> dart pub publish --dry-run"
dart pub publish --dry-run

if $dry_run; then
  echo "==> Dry run only; not publishing."
  exit 0
fi

echo "==> dart pub publish"
dart pub publish

echo "==> Published nocterm_hooks $version to pub.dev"
