#!/usr/bin/env bash
#
# checkpoint-reminder.sh — internOS stale STATUS.md detector
#
# Scans all active workstreams in an internOS workspace and reports those
# whose STATUS.md hasn't been updated within a configurable threshold.
#
# Usage: bash checkpoint-reminder.sh <workspace-path> [days-threshold]
#   days-threshold defaults to 3
#
# Exit:  0 if all fresh, 1 if stale workstreams found

set -euo pipefail

# --- Args -------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
    echo "Usage: checkpoint-reminder.sh <workspace-path> [days-threshold]"
    echo "  e.g. checkpoint-reminder.sh ~/.hermes/workspace 3"
    exit 2
fi

WORKSPACE="$1"
THRESHOLD_DAYS="${2:-3}"
PROJECTS_DIR="$WORKSPACE/projects"

if [[ ! -d "$PROJECTS_DIR" ]]; then
    echo "Error: $PROJECTS_DIR does not exist"
    exit 2
fi

# --- Platform-compatible date math ------------------------------------------

# Get file modification time in epoch seconds (Linux + macOS)
file_mtime() {
    local file="$1"
    if stat --version &>/dev/null; then
        # GNU stat (Linux)
        stat -c '%Y' "$file"
    else
        # BSD stat (macOS)
        stat -f '%m' "$file"
    fi
}

now_epoch() {
    date +%s
}

epoch_to_date() {
    if date --version &>/dev/null; then
        # GNU date (Linux)
        date -d "@$1" '+%Y-%m-%d'
    else
        # BSD date (macOS)
        date -r "$1" '+%Y-%m-%d'
    fi
}

# --- State -------------------------------------------------------------------

TOTAL_WORKSTREAMS=0
TOTAL_STALE=0
NOW=$(now_epoch)
THRESHOLD_SECS=$((THRESHOLD_DAYS * 86400))

# --- Helpers -----------------------------------------------------------------

warn() {
    echo "  STALE $1"
    ((TOTAL_STALE++)) || true
}

ok() {
    echo "  OK    $1"
}

# --- Main scan ---------------------------------------------------------------

echo "internOS Checkpoint Reminder"
echo "Workspace: $WORKSPACE"
echo "Threshold: $THRESHOLD_DAYS day(s)"
echo "$(date -u '+%Y-%m-%d %H:%M UTC')"
echo "========================================"

for project_dir in "$PROJECTS_DIR"/*/; do
    [[ -d "$project_dir" ]] || continue

    project_name=$(basename "$project_dir")
    ws_dir="$project_dir/workstreams"
    [[ -d "$ws_dir" ]] || continue

    project_stale=0
    project_ws=0
    has_workstreams=false

    for ws_path in "$ws_dir"/*/; do
        [[ -d "$ws_path" ]] || continue

        ws_name=$(basename "$ws_path")

        # Skip archived
        [[ "$ws_name" == "archived" ]] && continue

        has_workstreams=true
        ((TOTAL_WORKSTREAMS++)) || true
        ((project_ws++)) || true

        status_file="$ws_path/STATUS.md"

        if [[ ! -f "$status_file" ]]; then
            warn "$project_name/$ws_name — STATUS.md missing"
            ((project_stale++)) || true
            continue
        fi

        mtime=$(file_mtime "$status_file")
        age_secs=$((NOW - mtime))
        age_days=$((age_secs / 86400))
        last_modified=$(epoch_to_date "$mtime")

        if [[ $age_secs -gt $THRESHOLD_SECS ]]; then
            warn "$project_name/$ws_name — last updated $last_modified ($age_days day(s) ago)"
            ((project_stale++)) || true
        else
            ok "$project_name/$ws_name — updated $last_modified"
        fi
    done

    if $has_workstreams; then
        echo ""
        echo "  $project_name: $project_ws workstream(s), $project_stale stale"
        echo ""
    fi
done

# --- Summary -----------------------------------------------------------------

echo "========================================"
echo "Summary: $TOTAL_WORKSTREAMS workstream(s), $TOTAL_STALE stale"

if [[ $TOTAL_STALE -gt 0 ]]; then
    echo "Status: STALE WORKSTREAMS FOUND"
    exit 1
else
    echo "Status: ALL FRESH"
    exit 0
fi
