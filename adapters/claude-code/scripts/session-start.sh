#!/usr/bin/env bash
#
# session-start.sh — Claude Code SessionStart hook for internOS workstreams.
#
# Runs at the beginning of every Claude Code session. If the working
# directory is inside an internOS workstream, emits a structured system
# reminder via the SessionStart hook's `additionalContext` mechanism so
# Claude knows the workstream context BEFORE its first response token.
#
# What gets pre-loaded:
#   - BRIEF.md identity header (thread_id, project, owner, etc.)
#   - STATUS.md in full (≤10 lines by design — the heartbeat)
#   - Last 3 lines of SESSIONS.md (continuity from prior sessions)
#   - Open tick.md tasks tagged with this workstream
#   - Warnings written by the previous SessionEnd, if any
#
# What does NOT get pre-loaded:
#   - Full BRIEF.md body (one cheap read away when the turn requires it)
#   - MEMORY.md, DECISIONS.md, RESOURCES.md, STAKEHOLDERS.md (Tier 2/3 —
#     escalate on demand, not by default)
#
# Outputs Claude Code SessionStart hook JSON on stdout:
#   {"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"..."}}
#
# Exit:
#   0  always (silent no-op outside a workstream).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
RESOLVE="$SCRIPT_DIR/resolve-thread.sh"

# Resolve workstream. exit 1 (no workstream) → silent. exit 2 (binding broken)
# → emit a warning reminder so Claude tells the human rather than starting
# work blind. exit 3 (config error) → silent; the resolver itself printed.

set +e
workstream_dir="$("$RESOLVE" 2>/dev/null)"
resolve_exit=$?
set -e

emit_context() {
    local body="$1"
    # Escape for JSON: backslashes, double quotes, newlines.
    local escaped
    escaped=$(printf '%s' "$body" \
        | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' \
        | awk 'BEGIN{ORS="\\n"} {print}')
    # Strip the trailing literal "\n" that awk adds after the last line.
    escaped="${escaped%\\n}"
    printf '{"hookSpecificOutput":{"hookEventName":"SessionStart","additionalContext":"%s"}}\n' "$escaped"
}

if [[ $resolve_exit -eq 2 ]]; then
    emit_context "internOS: workstream binding is broken in the current working directory.

\`resolve-thread.sh\` exited 2 — typically BRIEF.md is missing or its thread_id does not match the canonical \`claude-code:projects/<project>/workstreams/<name>\` form.

Stop and ask the human what happened. Do not silently fix the file or start operating on a similarly-named workstream."
    exit 0
fi

if [[ $resolve_exit -ne 0 || -z "$workstream_dir" ]]; then
    # Either no workstream (exit 1) or config error (exit 3). Silent.
    exit 0
fi

# --- Read context files -----------------------------------------------------

ws_rel="${workstream_dir#${INTERNOS_WORKSPACE%/}/}"

# BRIEF identity header — first ~12 lines, which contain the YAML-ish id block.
brief_header=""
if [[ -f "$workstream_dir/BRIEF.md" ]]; then
    brief_header=$(head -12 "$workstream_dir/BRIEF.md")
fi

status=""
if [[ -f "$workstream_dir/STATUS.md" ]]; then
    status=$(cat "$workstream_dir/STATUS.md")
fi

sessions_tail=""
if [[ -f "$workstream_dir/SESSIONS.md" ]]; then
    # Last 3 actual entries (lines starting with a date), not headers.
    sessions_tail=$(grep -E '^[0-9]{4}-' "$workstream_dir/SESSIONS.md" 2>/dev/null | tail -3 || true)
fi

# tick.md task list — only run if `tick` is on PATH.
ws_name="$(basename "$workstream_dir")"
tick_tasks=""
if command -v tick >/dev/null 2>&1; then
    # tick may not support --json in older versions; capture whatever it gives.
    tick_tasks=$(cd "$workstream_dir" && tick list --tag "$ws_name" 2>/dev/null | head -20 || true)
fi

# Warnings from previous SessionEnd
warnings=""
if [[ -f "$workstream_dir/.internos-warnings" ]]; then
    warnings=$(cat "$workstream_dir/.internos-warnings")
fi

# --- Compose the system reminder -------------------------------------------

body="internOS workstream resolved · ${ws_rel:-$workstream_dir}

== BRIEF identity =="
[[ -n "$brief_header" ]] && body="${body}
${brief_header}" || body="${body}
(BRIEF.md missing or empty)"

body="${body}

== STATUS =="
[[ -n "$status" ]] && body="${body}
${status}" || body="${body}
(STATUS.md missing or empty)"

body="${body}

== Last 3 sessions =="
[[ -n "$sessions_tail" ]] && body="${body}
${sessions_tail}" || body="${body}
(no prior sessions logged)"

body="${body}

== Open tick tasks (tag: ${ws_name}) =="
if [[ -n "$tick_tasks" ]]; then
    body="${body}
${tick_tasks}"
elif command -v tick >/dev/null 2>&1; then
    body="${body}
(no tasks tagged \"${ws_name}\")"
else
    body="${body}
(tick command not found on PATH — task list unavailable)"
fi

if [[ -n "$warnings" ]]; then
    body="${body}

== Warnings from previous session =="
    body="${body}
${warnings}"
fi

body="${body}

(BRIEF body, MEMORY, DECISIONS, RESOURCES, STAKEHOLDERS are NOT pre-loaded — read them when the current turn requires them.)"

emit_context "$body"
exit 0
