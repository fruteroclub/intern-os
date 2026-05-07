#!/usr/bin/env bash
#
# extract-changelog.sh — Extract release notes for a version from CHANGELOG.md
#
# Usage: bash extract-changelog.sh <version-tag>
#   e.g. bash extract-changelog.sh v0.3.2
#
# Outputs the CHANGELOG.md section for that version to stdout.
# Exit 0 if found, 2 on usage/missing-file errors.
# Empty output indicates no matching entry — caller should test with `[ -s ]`.

set -euo pipefail

VERSION="${1:-}"
if [[ -z "$VERSION" ]]; then
    echo "Usage: extract-changelog.sh <version-tag>" >&2
    exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

if [[ ! -f "$CHANGELOG" ]]; then
    echo "Error: $CHANGELOG not found" >&2
    exit 2
fi

awk -v ver="$VERSION" '
    /^## / {
        if (found) exit
        if (index($0, ver) > 0) { found=1; next }
    }
    found { print }
' "$CHANGELOG"
