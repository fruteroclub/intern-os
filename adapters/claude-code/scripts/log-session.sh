#!/usr/bin/env bash
#
# log-session.sh — Append a session entry to the active workstream's SESSIONS.md.
#
# Records that a Claude Code session touched a workstream. Threads are the unit
# of work; sessions are individual conversations within a thread. SESSIONS.md is
# append-only and exists to trace decisions back to specific /resume conversations.
#
# Usage:
#   log-session.sh <session-id> [<summary>]      # explicit args
#   <hook-json> | log-session.sh                 # reads {"session_id": "..."} on stdin
#
# Reads $PWD and $INTERNOS_WORKSPACE (same resolution as resolve-thread.sh).
# If pwd is not inside a workstream, exits 0 silently — sessions outside
# workstreams are not internOS's concern.
#
# Entry format (one line per session):
#   YYYY-MM-DD HH:MM · <session-id> · <summary>
#
# A summary is optional. If omitted, the line is written without one and can
# be filled in later by Claude during the end-of-session protocol.

set -euo pipefail

SESSION_ID=""
SUMMARY=""

if [[ $# -ge 1 ]]; then
    SESSION_ID="$1"
    SUMMARY="${2:-}"
elif [[ ! -t 0 ]]; then
    # Stdin is a pipe — assume Claude Code hook JSON.
    # Pull out session_id without requiring jq. Tolerates surrounding whitespace.
    SESSION_ID="$(
        sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        | head -n1
    )"
fi

if [[ -z "$SESSION_ID" ]]; then
    echo "log-session: no session id (pass as arg or pipe hook JSON on stdin)" >&2
    exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
workstream_dir="$("$SCRIPT_DIR/resolve-thread.sh" 2>/dev/null || true)"

if [[ -z "$workstream_dir" ]]; then
    # No active workstream — session is not bound to a thread. Silent no-op.
    exit 0
fi

sessions_file="$workstream_dir/SESSIONS.md"
if [[ ! -f "$sessions_file" ]]; then
    cat > "$sessions_file" <<EOF
# SESSIONS

Append-only log of Claude Code sessions that touched this workstream.
One line per session: \`<timestamp> · <session-id> · <one-line summary>\`.
The thread (this workstream) is the unit of work; sessions are instances.

EOF
fi

timestamp="$(date '+%Y-%m-%d %H:%M')"
if [[ -n "$SUMMARY" ]]; then
    printf '%s · %s · %s\n' "$timestamp" "$SESSION_ID" "$SUMMARY" >> "$sessions_file"
else
    printf '%s · %s\n' "$timestamp" "$SESSION_ID" >> "$sessions_file"
fi
