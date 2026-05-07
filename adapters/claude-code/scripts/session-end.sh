#!/usr/bin/env bash
#
# session-end.sh — Claude Code SessionEnd hook for internOS workstreams.
#
# Runs at the actual end of a Claude Code session (NOT per agent turn — that's
# the `Stop` event, which is the wrong attach point). Performs the housekeeping
# that internOS doctrine describes but that previously relied on Claude
# remembering: stamp BRIEF.md last_updated, append a SESSIONS.md entry, run
# `sync-check.sh --workstream` on the active workstream and write findings to
# `.internos-warnings` so the next SessionStart can surface them.
#
# Reads the Claude Code hook payload as JSON from stdin (expects `session_id`).
# If pwd is not inside any workstream, exits 0 silently — sessions outside a
# workstream are not internOS's concern.
#
# Exit:
#   0  always (silent no-op outside a workstream; non-fatal sync-check
#      findings are recorded, not raised, since the hook fires at session end
#      where there is no agent left to react to errors).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
RESOLVE="$SCRIPT_DIR/resolve-thread.sh"

# Resolve workstream from $PWD. If absent or unresolved, silent no-op.
workstream_dir="$("$RESOLVE" 2>/dev/null || true)"
if [[ -z "$workstream_dir" ]]; then
    exit 0
fi

# --- Pull session_id from stdin JSON (no jq dependency) ---------------------

session_id=""
if [[ ! -t 0 ]]; then
    session_id="$(
        sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
        | head -n1
    )"
fi
# session_id may legitimately be empty if the hook payload doesn't include it
# (older Claude Code versions, manual invocation). The rest of the script
# still does useful work; we just write the SESSIONS.md entry without an ID.

# --- Stamp BRIEF.md `last_updated` ------------------------------------------

brief="$workstream_dir/BRIEF.md"
today="$(date '+%Y-%m-%d')"

if [[ -f "$brief" ]]; then
    if grep -q '^[[:space:]]*last_updated[[:space:]]*:' "$brief"; then
        # Replace existing line in place. Use a temp file for portability
        # across BSD/GNU sed differences.
        tmp="$(mktemp)"
        awk -v today="$today" '
            BEGIN { replaced = 0 }
            /^[[:space:]]*last_updated[[:space:]]*:/ && !replaced {
                print "last_updated: " today
                replaced = 1
                next
            }
            { print }
        ' "$brief" > "$tmp" && mv "$tmp" "$brief"
    else
        # Insert after the `created:` line if present, else after the
        # thread_id line. If neither is found, append to file.
        tmp="$(mktemp)"
        awk -v today="$today" '
            BEGIN { inserted = 0 }
            { print }
            !inserted && /^[[:space:]]*created[[:space:]]*:/ {
                print "last_updated: " today
                inserted = 1
            }
        ' "$brief" > "$tmp"
        if ! grep -q '^last_updated:' "$tmp"; then
            # `created:` not found — try after thread_id.
            awk -v today="$today" '
                BEGIN { inserted = 0 }
                { print }
                !inserted && /^[[:space:]]*thread_id[[:space:]]*:/ {
                    print "last_updated: " today
                    inserted = 1
                }
            ' "$brief" > "$tmp"
        fi
        if ! grep -q '^last_updated:' "$tmp"; then
            # Still nowhere obvious — append.
            printf 'last_updated: %s\n' "$today" >> "$tmp"
        fi
        mv "$tmp" "$brief"
    fi
fi

# --- Append SESSIONS.md entry -----------------------------------------------

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
if [[ -n "$session_id" ]]; then
    printf '%s · %s\n' "$timestamp" "$session_id" >> "$sessions_file"
else
    printf '%s · (session ended)\n' "$timestamp" >> "$sessions_file"
fi

# --- Run sync-check on this workstream, capture findings --------------------
#
# We look up the framework-agnostic sync-check.sh in the same install root.
# When installed at ~/.claude/skills/intern-os/, the layout we ship is:
#   ~/.claude/skills/intern-os/scripts/        (this file, resolve-thread, log-session)
# The framework-agnostic sync-check is shipped from the repo's
# intern-os/scripts/. We copy it next to the adapter scripts during install,
# so look for it as a sibling first; fall back to common repo paths if running
# from a checkout for testing.

sync_check=""
for candidate in \
    "$SCRIPT_DIR/sync-check.sh" \
    "$SCRIPT_DIR/../../../intern-os/scripts/sync-check.sh"
do
    if [[ -x "$candidate" || -f "$candidate" ]]; then
        sync_check="$candidate"
        break
    fi
done

warnings_file="$workstream_dir/.internos-warnings"
rm -f "$warnings_file"

if [[ -n "$sync_check" ]]; then
    # Capture stdout (findings) and stderr (errors) separately.
    findings="$(bash "$sync_check" --workstream "$workstream_dir" 2>/dev/null || true)"
    if [[ -n "$findings" ]]; then
        printf '%s\n' "$findings" > "$warnings_file"
    fi
fi

exit 0
