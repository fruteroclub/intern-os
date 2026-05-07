#!/usr/bin/env bash
#
# resolve-thread.sh — Resolve the active workstream thread from pwd (Claude Code).
#
# Walks up from $PWD looking for an internOS workstream directory of the form
# <workspace>/projects/<project>/workstreams/<workstream>/. If found, verifies
# that BRIEF.md exists and its thread_id matches the expected canonical form
# `claude-code:projects/<project>/workstreams/<workstream>`.
#
# This is the Claude Code analogue of the Discord/Slack thread_id binding:
# the working directory IS the thread. Resolution is exact and deterministic —
# no fuzzy matching, no fallback, no guessing.
#
# Usage:
#   resolve-thread.sh                       # uses $PWD and $INTERNOS_WORKSPACE
#   resolve-thread.sh <pwd> [<workspace>]   # explicit args (testing)
#
# Env:
#   INTERNOS_WORKSPACE  Workspace root containing projects/ (REQUIRED — no default).
#                       Set this to the directory whose `projects/` subdirectory
#                       holds your project directories.
#
# Output (stdout, on success): absolute path to the active workstream directory
# Exit codes:
#   0  active workstream resolved (path printed to stdout)
#   1  pwd is not inside a workstream subtree (no active thread — silent, expected)
#   2  workstream directory found but BRIEF.md missing or thread_id mismatched
#   3  usage error (missing INTERNOS_WORKSPACE, bad start dir, etc.)

set -euo pipefail

# --- Args -------------------------------------------------------------------

START_DIR="${1:-$PWD}"
WORKSPACE="${2:-${INTERNOS_WORKSPACE:-}}"

if [[ -z "$WORKSPACE" ]]; then
    cat >&2 <<'EOF'
resolve-thread: INTERNOS_WORKSPACE is not set.

Set it to the directory that contains your `projects/` directory. Example:

    export INTERNOS_WORKSPACE="$HOME/workspace"

There is no implicit default — the Claude Code adapter requires this to be
explicit so it never silently picks up a stale or unrelated workspace.
EOF
    exit 3
fi

# Normalize to absolute paths so prefix-matching is well-defined.
if [[ ! -d "$START_DIR" ]]; then
    echo "resolve-thread: start dir not found: $START_DIR" >&2
    exit 3
fi
START_DIR="$(cd "$START_DIR" && pwd -P)"

if [[ ! -d "$WORKSPACE" ]]; then
    # Workspace configured but doesn't exist on disk. Treat as "no thread"
    # silently so the skill doesn't bark in unrelated sessions; the user will
    # only notice if they actually try to operate a workstream.
    exit 1
fi
WORKSPACE="$(cd "$WORKSPACE" && pwd -P)"

# --- Walk up from $START_DIR, looking for a workstream dir ------------------
#
# A workstream dir is exactly: <WORKSPACE>/projects/<project>/workstreams/<name>
# We walk up until we find a directory whose path matches that shape, OR we
# leave the workspace subtree.

# If we're not under the workspace at all, there's no thread to resolve.
case "$START_DIR/" in
    "$WORKSPACE"/*) : ;;
    *) exit 1 ;;
esac

current="$START_DIR"
workstream_dir=""

while [[ "$current" == "$WORKSPACE"/* ]]; do
    # Match: <WORKSPACE>/projects/<project>/workstreams/<name>
    rel="${current#$WORKSPACE/}"
    if [[ "$rel" =~ ^projects/[^/]+/workstreams/[^/]+$ ]]; then
        workstream_dir="$current"
        break
    fi
    current="$(dirname "$current")"
done

if [[ -z "$workstream_dir" ]]; then
    exit 1
fi

# --- Verify BRIEF.md and thread_id ------------------------------------------

brief="$workstream_dir/BRIEF.md"
if [[ ! -f "$brief" ]]; then
    echo "resolve-thread: workstream dir has no BRIEF.md: $workstream_dir" >&2
    exit 2
fi

rel_workstream="${workstream_dir#$WORKSPACE/}"
expected_thread_id="claude-code:$rel_workstream"

# Extract the thread_id value. Accept formats like:
#   thread_id: claude-code:projects/foo/workstreams/bar
#   thread_id:claude-code:projects/foo/workstreams/bar
# Trim surrounding whitespace.
actual_thread_id="$(
    awk -F: '
        /^[[:space:]]*thread_id[[:space:]]*:/ {
            sub(/^[^:]*:[[:space:]]*/, "", $0)
            gsub(/[[:space:]]+$/, "", $0)
            print
            exit
        }
    ' "$brief"
)"

if [[ -z "$actual_thread_id" ]]; then
    echo "resolve-thread: BRIEF.md has no thread_id: $brief" >&2
    echo "resolve-thread: expected: $expected_thread_id" >&2
    exit 2
fi

if [[ "$actual_thread_id" != "$expected_thread_id" ]]; then
    echo "resolve-thread: thread_id mismatch in $brief" >&2
    echo "  expected: $expected_thread_id" >&2
    echo "  found:    $actual_thread_id" >&2
    echo "  This usually means the workstream was moved or scaffolded elsewhere." >&2
    echo "  Stop and ask the human — never guess." >&2
    exit 2
fi

echo "$workstream_dir"
