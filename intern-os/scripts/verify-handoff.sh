#!/usr/bin/env bash
#
# verify-handoff.sh — Verify a handoff manifest against intern-os doctrine.
#
# Usage: bash verify-handoff.sh <manifest-path>
#
# Runs the four named binding_checks from schema v1, in order:
#   1. workstream_path_exists       — workstream_path resolves to a directory
#   2. brief_md_exists              — BRIEF.md is present at workstream_path/BRIEF.md
#   3. thread_id_matches            — BRIEF.md's thread_id exactly equals manifest's
#   4. load_required_paths_exist    — every load.required path resolves
#
# Exit codes:
#   0 — all checks passed
#   3 — a named check failed (failing check name printed to stderr)
#   2 — usage / missing manifest file / parse error
#
# Schema: intern-os/schemas/handoff-v1.yaml
# Spec:   docs/specs/v0.4.0-isolated-handoff.md
#
# Dependencies: bash, awk, sed, grep — all POSIX standard. No yq, no python.

set -euo pipefail

usage() {
    echo "Usage: bash verify-handoff.sh <manifest-path>" >&2
    exit 2
}

[ $# -eq 1 ] || usage
MANIFEST="$1"

[ -f "$MANIFEST" ] || { echo "Error: manifest not found: $MANIFEST" >&2; exit 2; }

# ── Minimal YAML field extractor ──────────────────────────────────────────
# Extracts a top-level scalar field's value. Strips surrounding quotes.
# Not a general YAML parser — handles the flat fields v1 manifests need.
# For nested fields (load.required, write_back.artifact_path), the callers
# below use awk to walk the indented block.
#
# Limitations (acceptable for v1):
# - assumes top-level fields are not indented
# - assumes one field per line (no flow-style mappings on shared lines)
# - quoted values use ", ', or none — multiline strings (|, >) are NOT
#   supported for the four binding-check fields, all of which are scalar.

extract_scalar() {
    local field="$1"
    awk -v key="^${field}:" '
        $0 ~ key {
            sub(key, "", $0)
            sub(/^[[:space:]]+/, "", $0)
            sub(/[[:space:]]+#.*$/, "", $0)
            sub(/^"/, "", $0); sub(/"$/, "", $0)
            sub(/^'\''/, "", $0); sub(/'\''$/, "", $0)
            print
            exit
        }
    ' "$MANIFEST"
}

# Extract every path under a nested list, e.g. load.required:
#   load:
#     required:
#       - BRIEF.md
#       - STATUS.md
# extract_list <parent-key> <child-key>
extract_list() {
    local parent="$1"
    local child="$2"
    awk -v parent="^${parent}:" -v child="^[[:space:]]+${child}:" '
        $0 ~ parent { in_parent = 1; next }
        in_parent && $0 ~ child { in_list = 1; next }
        in_list {
            if ($0 ~ /^[[:space:]]+-[[:space:]]/) {
                line = $0
                sub(/^[[:space:]]+-[[:space:]]+/, "", line)
                sub(/[[:space:]]+#.*$/, "", line)
                sub(/^"/, "", line); sub(/"$/, "", line)
                sub(/^'\''/, "", line); sub(/'\''$/, "", line)
                print line
            } else if ($0 ~ /^[^[:space:]]/) {
                # Hit a new top-level key
                exit
            } else if ($0 ~ /^[[:space:]]+[a-zA-Z_]+:/ && in_list) {
                # Hit a sibling key under the same parent
                exit
            }
        }
    ' "$MANIFEST"
}

# Extract a nested scalar: extract_nested <parent> <child>
extract_nested() {
    local parent="$1"
    local child="$2"
    awk -v parent="^${parent}:" -v child="^[[:space:]]+${child}:" '
        $0 ~ parent { in_parent = 1; next }
        in_parent && $0 ~ child {
            line = $0
            sub(child, "", line)
            sub(/^[[:space:]]+/, "", line)
            sub(/[[:space:]]+#.*$/, "", line)
            sub(/^"/, "", line); sub(/"$/, "", line)
            sub(/^'\''/, "", line); sub(/'\''$/, "", line)
            print line
            exit
        }
        in_parent && $0 ~ /^[^[:space:]]/ { exit }
    ' "$MANIFEST"
}

fail() {
    local check="$1"
    local detail="${2:-}"
    if [ -n "$detail" ]; then
        echo "FAIL: $check — $detail" >&2
    else
        echo "FAIL: $check" >&2
    fi
    exit 3
}

# ── Sanity: schema version ────────────────────────────────────────────────
SCHEMA_VERSION=$(extract_scalar "internos_handoff")
if [ "$SCHEMA_VERSION" != "v1" ]; then
    echo "Error: unsupported schema version: '${SCHEMA_VERSION}' (expected 'v1')" >&2
    exit 2
fi

# ── Extract fields ────────────────────────────────────────────────────────
WORKSTREAM_PATH=$(extract_scalar "workstream_path")
THREAD_ID=$(extract_scalar "thread_id")

[ -n "$WORKSTREAM_PATH" ] || { echo "Error: workstream_path is empty" >&2; exit 2; }
[ -n "$THREAD_ID" ] || { echo "Error: thread_id is empty" >&2; exit 2; }

# ── Check 1: workstream_path_exists ───────────────────────────────────────
[ -d "$WORKSTREAM_PATH" ] || fail "workstream_path_exists" "no such directory: $WORKSTREAM_PATH"

# ── Check 2: brief_md_exists ──────────────────────────────────────────────
BRIEF="$WORKSTREAM_PATH/BRIEF.md"
[ -f "$BRIEF" ] || fail "brief_md_exists" "no BRIEF.md at $BRIEF"

# ── Check 3: thread_id_matches ────────────────────────────────────────────
# BRIEF.md is markdown but contains a `thread_id: <value>` line per intern-os
# template. Match line-anchored, strip surrounding whitespace, no quote strip
# (BRIEF.md convention doesn't quote).
BRIEF_THREAD_ID=$(grep -E '^[[:space:]]*thread_id:' "$BRIEF" | head -1 | sed -E 's/^[[:space:]]*thread_id:[[:space:]]*//; s/[[:space:]]+$//' || true)

if [ "$BRIEF_THREAD_ID" != "$THREAD_ID" ]; then
    fail "thread_id_matches" "manifest='$THREAD_ID' BRIEF.md='$BRIEF_THREAD_ID'"
fi

# ── Check 4: load_required_paths_exist ────────────────────────────────────
# Read each path under load.required; resolve relative paths against
# workstream_path. Empty list is a manifest error.
REQUIRED_PATHS=$(extract_list "load" "required")
if [ -z "$REQUIRED_PATHS" ]; then
    echo "Error: load.required is empty (at minimum BRIEF.md, STATUS.md required)" >&2
    exit 2
fi

while IFS= read -r path; do
    [ -n "$path" ] || continue
    case "$path" in
        /*) resolved="$path" ;;
        *)  resolved="$WORKSTREAM_PATH/$path" ;;
    esac
    [ -e "$resolved" ] || fail "load_required_paths_exist" "missing: $resolved"
done <<EOF
$REQUIRED_PATHS
EOF

# ── All checks passed ─────────────────────────────────────────────────────
echo "OK: all binding_checks passed for $MANIFEST"
exit 0
