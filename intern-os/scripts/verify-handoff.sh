#!/usr/bin/env bash
#
# verify-handoff.sh — Verify a handoff manifest against intern-os doctrine.
#
# Usage: bash verify-handoff.sh <manifest-path>
#
# Two layers of validation, run in order:
#
# (A) Well-formedness (manifest is structurally valid). Exit 2 on failure.
#     - schema version is v1
#     - required blocks are present (task:, write_back:, load:)
#     - workstream_path, thread_id are non-empty
#     - task.success_condition and task.stop_condition are non-empty
#     - write_back.artifact_path is under "handoffs/"
#     - write_back.artifact_schema has at least one entry
#     - write_back.also_append targets are in {MEMORY.md}
#     - load.required uses block-style YAML lists and includes BRIEF.md
#       and STATUS.md at minimum
#     - Flow-style YAML (`[a, b]`) is rejected for every list field the
#       verifier consumes (load.required, write_back.also_append,
#       write_back.artifact_schema). Use block form (`- a` on separate
#       lines) instead.
#
# (B) Named binding_checks (manifest matches reality on disk). Exit 3 on failure.
#     1. workstream_path_exists       — workstream_path resolves to a directory
#     2. brief_md_exists              — BRIEF.md is present at workstream_path/BRIEF.md
#     3. thread_id_matches            — BRIEF.md's thread_id equals manifest's
#                                       (after stripping surrounding whitespace
#                                       from BOTH sides — manifest and BRIEF.md)
#     4. load_required_paths_exist    — every load.required path resolves
#
# Note on the manifest's `binding_checks` array: in v1 this is documentary —
# the v1 verifier always runs the four checks above unconditionally and in
# this fixed order. Adapters and future verifier versions (v2+) may parse
# the array and dispatch named checks; v1 does not.
#
# Exit codes:
#   0 — all checks passed
#   2 — manifest malformed (well-formedness) OR usage / missing-file error
#   3 — a named binding check failed (failing check name printed to stderr)
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

# Allowlist for write_back.also_append targets in v1.
# Specialists may append to MEMORY.md only; everything else is coordinator-owned.
ALLOWED_APPEND_TARGETS="MEMORY.md"

# ── Minimal YAML field extractor ──────────────────────────────────────────
# Extracts a top-level scalar field's value. Strips surrounding quotes.
# Not a general YAML parser — handles the flat fields v1 manifests need.

extract_scalar() {
    local field="$1"
    awk -v key="^${field}:" '
        $0 ~ key {
            sub(key, "", $0)
            sub(/^[[:space:]]+/, "", $0)
            sub(/[[:space:]]+#.*$/, "", $0)
            sub(/[[:space:]]+$/, "", $0)
            sub(/^"/, "", $0); sub(/"$/, "", $0)
            sub(/^'\''/, "", $0); sub(/'\''$/, "", $0)
            print
            exit
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
                exit
            } else if ($0 ~ /^[[:space:]]+[a-zA-Z_]+:/ && in_list) {
                exit
            }
        }
    ' "$MANIFEST"
}

# Detect if a child key is using NON-EMPTY flow-style YAML, e.g.
#   required: [BRIEF.md, STATUS.md]
# v1 does not support flow style for non-empty lists — those need to use
# block form so the verifier's awk-based extractors can parse them. Empty
# flow-style (`field: []`) is allowed (semantically equivalent to no field;
# acts as a placeholder in templates).
# detect_flow_style <parent> <child>  →  prints matched line if found
#
# Match: `<child>: [<at-least-one-non-bracket-non-whitespace>]`.
# Uses [[]] / []] character classes for literal `[` / `]` — backslash
# escaping in awk -v values varies across BSD/GNU awk.
detect_flow_style() {
    local parent="$1"
    local child="$2"
    awk -v parent="^${parent}:" -v child="^[[:space:]]+${child}:[[:space:]]*[[][[:space:]]*[^][:space:]]" '
        $0 ~ parent { in_parent = 1; next }
        in_parent && $0 ~ child { print; exit }
        in_parent && $0 ~ /^[^[:space:]]/ { exit }
    ' "$MANIFEST"
}

# Extract list entries' nested field — for things like write_back.also_append's
# `target:` values. Returns one value per matching nested key under each
# list item in <parent>.<list_key>.
# extract_list_field <parent> <list_key> <nested_field>
extract_list_field() {
    local parent="$1"
    local list_key="$2"
    local field="$3"
    awk -v parent="^${parent}:" -v list_key="^[[:space:]]+${list_key}:" -v field="${field}:" '
        $0 ~ parent { in_parent = 1; next }
        in_parent && $0 ~ list_key { in_list = 1; next }
        in_list && $0 ~ /^[[:space:]]+-[[:space:]]/ {
            line = $0
            sub(/^[[:space:]]+-[[:space:]]+/, "", line)
            if (line ~ ("^" field)) {
                sub(("^" field "[[:space:]]*"), "", line)
                sub(/[[:space:]]+#.*$/, "", line)
                sub(/^"/, "", line); sub(/"$/, "", line)
                sub(/^'\''/, "", line); sub(/'\''$/, "", line)
                print line
            }
            next
        }
        in_list && $0 ~ /^[[:space:]]+[a-zA-Z_]+:/ {
            # nested field on a continuation line of the previous list item
            line = $0
            sub(/^[[:space:]]+/, "", line)
            if (line ~ ("^" field)) {
                sub(("^" field "[[:space:]]*"), "", line)
                sub(/[[:space:]]+#.*$/, "", line)
                sub(/^"/, "", line); sub(/"$/, "", line)
                sub(/^'\''/, "", line); sub(/'\''$/, "", line)
                print line
            }
            next
        }
        in_list && $0 ~ /^[^[:space:]]/ { exit }
    ' "$MANIFEST"
}

# Detect whether a top-level block (e.g. `task:`, `write_back:`) is present.
# Returns 0 if found, 1 otherwise.
has_block() {
    local block="$1"
    grep -qE "^${block}:" "$MANIFEST"
}

# Error helpers
malformed() {
    echo "Error: manifest malformed — $1" >&2
    exit 2
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

# ─────────────────────────────────────────────────────────────────────────
# Layer A — well-formedness (exit 2 on failure)
# ─────────────────────────────────────────────────────────────────────────

# A1: schema version
SCHEMA_VERSION=$(extract_scalar "internos_handoff")
if [ "$SCHEMA_VERSION" != "v1" ]; then
    malformed "unsupported schema version: '${SCHEMA_VERSION}' (expected 'v1')"
fi

# A2: required top-level blocks
has_block "task"       || malformed "missing required block: task:"
has_block "write_back" || malformed "missing required block: write_back:"
has_block "load"       || malformed "missing required block: load:"

# A3: required scalars
WORKSTREAM_PATH=$(extract_scalar "workstream_path")
THREAD_ID=$(extract_scalar "thread_id")
[ -n "$WORKSTREAM_PATH" ] || malformed "workstream_path is empty"
[ -n "$THREAD_ID" ]       || malformed "thread_id is empty"

# A4: required task.* scalars
TASK_SUCCESS=$(extract_nested "task" "success_condition")
[ -n "$TASK_SUCCESS" ] || malformed "task.success_condition is empty"
# stop_condition is a list; we check it has at least one entry below at A8

# A5: flow style is rejected for EVERY list field the verifier consumes.
# Hardcoded list of (parent, child) pairs covered by v1's well-formedness layer.
# binding_checks and artifact_schema are not iterated by the verifier (yet)
# but we still reject flow style for consistency with spec language.
for pair in "load required" "write_back also_append" "write_back artifact_schema" "binding_checks BINDING_CHECKS_FLAT" "task stop_condition"; do
    set -- $pair
    parent="$1"
    child="$2"
    # Special case: binding_checks is itself a top-level list, not nested.
    # The pattern below uses extract_list_top instead — but to keep v1 small,
    # we skip the top-level binding_checks flow-style check and rely on the
    # documentary-only stance documented in the header.
    [ "$child" = "BINDING_CHECKS_FLAT" ] && continue
    FLOW_HIT=$(detect_flow_style "$parent" "$child" || true)
    if [ -n "$FLOW_HIT" ]; then
        malformed "${parent}.${child} uses YAML flow style (e.g. '[a, b]'); v1 supports block style only — use '- a' on separate lines"
    fi
done

# A6: write_back.artifact_path must start with "handoffs/"
ARTIFACT_PATH=$(extract_nested "write_back" "artifact_path")
[ -n "$ARTIFACT_PATH" ] || malformed "write_back.artifact_path is empty"
case "$ARTIFACT_PATH" in
    handoffs/*) : ;;  # OK
    *) malformed "write_back.artifact_path must start with 'handoffs/' (got: '$ARTIFACT_PATH')" ;;
esac

# A7: write_back.also_append targets must be in allowlist
APPEND_TARGETS=$(extract_list_field "write_back" "also_append" "target" || true)
while IFS= read -r target; do
    [ -n "$target" ] || continue
    case " $ALLOWED_APPEND_TARGETS " in
        *" $target "*) : ;;  # OK
        *) malformed "write_back.also_append target '$target' not permitted in v1 (allowed: $ALLOWED_APPEND_TARGETS)" ;;
    esac
done <<EOF
$APPEND_TARGETS
EOF

# A8: write_back.artifact_schema must have at least one entry
ARTIFACT_SCHEMA=$(extract_list "write_back" "artifact_schema" || true)
[ -n "$ARTIFACT_SCHEMA" ] || malformed "write_back.artifact_schema must have at least one section name"

# A9: task.stop_condition must have at least one entry
STOP_CONDITIONS=$(extract_list "task" "stop_condition" || true)
[ -n "$STOP_CONDITIONS" ] || malformed "task.stop_condition must have at least one entry"

# A10: load.required must include BRIEF.md and STATUS.md at minimum
REQUIRED_PATHS=$(extract_list "load" "required")
if [ -z "$REQUIRED_PATHS" ]; then
    malformed "load.required is empty (at minimum BRIEF.md, STATUS.md required)"
fi
echo "$REQUIRED_PATHS" | grep -qxF "BRIEF.md"  || malformed "load.required must include 'BRIEF.md'"
echo "$REQUIRED_PATHS" | grep -qxF "STATUS.md" || malformed "load.required must include 'STATUS.md'"

# ─────────────────────────────────────────────────────────────────────────
# Layer B — named binding_checks (exit 3 on failure)
# ─────────────────────────────────────────────────────────────────────────

# B1: workstream_path_exists
[ -d "$WORKSTREAM_PATH" ] || fail "workstream_path_exists" "no such directory: $WORKSTREAM_PATH"

# B2: brief_md_exists
BRIEF="$WORKSTREAM_PATH/BRIEF.md"
[ -f "$BRIEF" ] || fail "brief_md_exists" "no BRIEF.md at $BRIEF"

# B3: thread_id_matches
# BRIEF.md is markdown but contains a `thread_id: <value>` line per intern-os
# template. We strip surrounding whitespace (incl. CR if BRIEF.md was authored
# on Windows) — this is documented behavior, not "no normalization."
BRIEF_THREAD_ID=$(grep -E '^[[:space:]]*thread_id:' "$BRIEF" | head -1 | sed -E 's/^[[:space:]]*thread_id:[[:space:]]*//; s/[[:space:]]+$//' || true)

if [ "$BRIEF_THREAD_ID" != "$THREAD_ID" ]; then
    fail "thread_id_matches" "manifest='$THREAD_ID' BRIEF.md='$BRIEF_THREAD_ID'"
fi

# B4: load_required_paths_exist (REQUIRED_PATHS already extracted in A10)

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

# ─────────────────────────────────────────────────────────────────────────
# All checks passed
# ─────────────────────────────────────────────────────────────────────────
echo "OK: all well-formedness and binding_checks passed for $MANIFEST"
exit 0
