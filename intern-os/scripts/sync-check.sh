#!/usr/bin/env bash
#
# sync-check.sh — internOS workspace health check
#
# Scans all projects and workstreams in an internOS workspace and reports
# mismatches between filesystem, thread_ids, and tick.md tasks.
#
# Usage: bash sync-check.sh <workspace-path>
# Exit:  0 if all healthy, 1 if issues found

set -euo pipefail

# --- Args -------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
    echo "Usage: sync-check.sh <workspace-path>"
    echo "  e.g. sync-check.sh ~/.hermes/workspace"
    exit 2
fi

WORKSPACE="$1"
PROJECTS_DIR="$WORKSPACE/projects"

if [[ ! -d "$PROJECTS_DIR" ]]; then
    echo "Error: $PROJECTS_DIR does not exist"
    exit 2
fi

# --- State -------------------------------------------------------------------

TOTAL_PROJECTS=0
TOTAL_WORKSTREAMS=0
TOTAL_ISSUES=0

EXPECTED_FILES=(BRIEF.md STATUS.md MEMORY.md DECISIONS.md STAKEHOLDERS.md RESOURCES.md)

# --- Helpers -----------------------------------------------------------------

warn() {
    echo "  WARN  $1"
    ((TOTAL_ISSUES++)) || true
}

ok() {
    echo "  OK    $1"
}

info() {
    echo "  INFO  $1"
}

# Extract thread_id from a BRIEF.md file.
# Handles both "thread_id: value" and "**thread_id:** value" formats.
extract_thread_id() {
    local file="$1"
    grep -oP '(?:^|\*\*?)thread_id:?\*?\*?\s*(.+)' "$file" 2>/dev/null \
        | sed 's/.*thread_id[*:]*\s*//' \
        | head -1 \
        | xargs
}

# Check if TICK.md contains a task tagged with the given workstream name.
check_tick_tag() {
    local tick_file="$1"
    local ws_name="$2"
    if [[ ! -f "$tick_file" ]]; then
        return 1
    fi
    grep -q "$ws_name" "$tick_file" 2>/dev/null
}

# --- Main scan ---------------------------------------------------------------

echo "internOS Sync Check"
echo "Workspace: $WORKSPACE"
echo "$(date -u '+%Y-%m-%d %H:%M UTC')"
echo "========================================"

for project_dir in "$PROJECTS_DIR"/*/; do
    [[ -d "$project_dir" ]] || continue

    project_name=$(basename "$project_dir")
    ((TOTAL_PROJECTS++)) || true
    project_issues=0
    project_ws=0

    echo ""
    echo "Project: $project_name"
    echo "----------------------------------------"

    # Check PROJECT.md
    if [[ -f "$project_dir/PROJECT.md" ]]; then
        ok "PROJECT.md exists"
    else
        warn "PROJECT.md missing (recommended since v2.1.0)"
        ((project_issues++)) || true
    fi

    # Check TICK.md
    tick_file="$project_dir/TICK.md"
    if [[ -f "$tick_file" ]]; then
        ok "TICK.md exists"
    else
        warn "TICK.md missing — no task tracking for this project"
        ((project_issues++)) || true
    fi

    # Check workstreams directory
    ws_dir="$project_dir/workstreams"
    if [[ ! -d "$ws_dir" ]]; then
        warn "workstreams/ directory missing"
        ((project_issues++)) || true
        continue
    fi

    for ws_path in "$ws_dir"/*/; do
        [[ -d "$ws_path" ]] || continue

        ws_name=$(basename "$ws_path")

        # Skip archived workstreams
        if [[ "$ws_name" == "archived" ]]; then
            info "Skipping archived/"
            continue
        fi

        ((TOTAL_WORKSTREAMS++)) || true
        ((project_ws++)) || true

        echo ""
        echo "  Workstream: $ws_name"

        # Check expected files
        missing_files=()
        for f in "${EXPECTED_FILES[@]}"; do
            if [[ ! -f "$ws_path/$f" ]]; then
                missing_files+=("$f")
            fi
        done

        if [[ ${#missing_files[@]} -gt 0 ]]; then
            warn "Missing files: ${missing_files[*]}"
            ((project_issues++)) || true
        else
            ok "All 6 workstream files present"
        fi

        # Check thread_id
        brief_file="$ws_path/BRIEF.md"
        if [[ -f "$brief_file" ]]; then
            thread_id=$(extract_thread_id "$brief_file")

            if [[ -z "$thread_id" ]]; then
                warn "thread_id is empty or missing in BRIEF.md"
                ((project_issues++)) || true
            else
                # Validate format: should be platform:id
                if [[ "$thread_id" =~ ^[a-z]+:.+ ]]; then
                    platform="${thread_id%%:*}"
                    id_part="${thread_id#*:}"

                    # Slack-specific: should have channel/thread_ts
                    if [[ "$platform" == "slack" && ! "$id_part" =~ / ]]; then
                        warn "thread_id ($thread_id) — Slack ID missing thread timestamp (expected slack:CHANNEL/THREAD_TS)"
                        ((project_issues++)) || true
                    else
                        ok "thread_id: $thread_id"
                    fi
                else
                    warn "thread_id format invalid: '$thread_id' (expected platform:id)"
                    ((project_issues++)) || true
                fi
            fi
        fi

        # Check tick.md task tag
        if [[ -f "$tick_file" ]]; then
            if check_tick_tag "$tick_file" "$ws_name"; then
                ok "Task tag '$ws_name' found in TICK.md"
            else
                warn "No task tagged '$ws_name' in TICK.md"
                ((project_issues++)) || true
            fi
        fi
    done

    echo ""
    echo "  $project_name: $project_ws workstream(s), $project_issues issue(s)"
done

# --- Summary -----------------------------------------------------------------

echo ""
echo "========================================"
echo "Summary: $TOTAL_PROJECTS project(s), $TOTAL_WORKSTREAMS workstream(s), $TOTAL_ISSUES issue(s)"

if [[ $TOTAL_ISSUES -gt 0 ]]; then
    echo "Status: ISSUES FOUND"
    exit 1
else
    echo "Status: ALL HEALTHY"
    exit 0
fi
