#!/usr/bin/env bash
#
# sync-check.sh — internOS workspace health check (v0.3.0)
#
# Scans all projects and workstreams in an internOS workspace and reports
# mismatches between filesystem, thread_ids, BRIEF.md identity fields,
# and tick.md tasks.
#
# Validates:
#   - PROJECT.md and TICK.md existence per project
#   - AGENTS.md presence per project (informational, not required)
#   - All 6 workstream files present
#   - thread_id in BRIEF.md: exists, valid format, no duplicates
#   - BRIEF.md identity fields: project, workstream, owner, created
#   - Workstream task tag in TICK.md
#   - STATUS.md size (target ≤10 lines)
#   - MEMORY.md size (target ≤80 lines)
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
TOTAL_NOTES=0

EXPECTED_FILES=(BRIEF.md STATUS.md MEMORY.md DECISIONS.md STAKEHOLDERS.md RESOURCES.md)

# Track all thread_ids to detect duplicates
declare -A SEEN_THREAD_IDS

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
    ((TOTAL_NOTES++)) || true
}

# Extract a field value from a markdown file.
# Handles "field: value" format (plain or with bold markers).
extract_field() {
    local file="$1"
    local field="$2"
    grep -oP "(?:^|\*\*?)${field}:?\*?\*?\s*(.+)" "$file" 2>/dev/null \
        | sed "s/.*${field}[*:]*\s*//" \
        | head -1 \
        | xargs
}

# Count non-empty, non-comment lines in a file.
count_content_lines() {
    local file="$1"
    grep -cve '^\s*$' -e '^\s*<!--' "$file" 2>/dev/null || echo "0"
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

echo "internOS Sync Check (v0.3.0)"
echo "Workspace: $WORKSPACE"
echo "$(date -u '+%Y-%m-%d %H:%M UTC')"
echo "========================================"

for project_dir in "$PROJECTS_DIR"/*/; do
    [[ -d "$project_dir" ]] || continue

    project_name=$(basename "$project_dir")

    # Skip archived projects
    if [[ "$project_name" == "archived" ]]; then
        continue
    fi

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
        warn "PROJECT.md missing"
        ((project_issues++)) || true
    fi

    # Check AGENTS.md (informational — optional but recognized)
    if [[ -f "$project_dir/AGENTS.md" ]]; then
        ok "AGENTS.md exists (project-level agent context)"
    else
        info "AGENTS.md not present (optional — project-level agent context)"
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

        # --- Check expected files ---

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

        # --- Check BRIEF.md identity fields ---

        brief_file="$ws_path/BRIEF.md"
        if [[ -f "$brief_file" ]]; then

            # thread_id (mandatory — resolution layer)
            thread_id=$(extract_field "$brief_file" "thread_id")

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

                    # Check for duplicate thread_ids
                    tid_key="$thread_id"
                    if [[ -n "${SEEN_THREAD_IDS[$tid_key]+x}" ]]; then
                        warn "thread_id ($thread_id) is duplicated — also used by ${SEEN_THREAD_IDS[$tid_key]}"
                        ((project_issues++)) || true
                    else
                        SEEN_THREAD_IDS[$tid_key]="$project_name/$ws_name"
                    fi
                else
                    warn "thread_id format invalid: '$thread_id' (expected platform:id)"
                    ((project_issues++)) || true
                fi
            fi

            # project field (expected in BRIEF.md)
            brief_project=$(extract_field "$brief_file" "project")
            if [[ -z "$brief_project" ]]; then
                info "BRIEF.md missing 'project' identity field"
            fi

            # workstream field (expected in BRIEF.md)
            brief_ws=$(extract_field "$brief_file" "workstream")
            if [[ -z "$brief_ws" ]]; then
                info "BRIEF.md missing 'workstream' identity field"
            fi

            # owner field (expected in BRIEF.md)
            brief_owner=$(extract_field "$brief_file" "owner")
            if [[ -z "$brief_owner" ]]; then
                info "BRIEF.md missing 'owner' identity field"
            fi

            # created field (expected in BRIEF.md)
            brief_created=$(extract_field "$brief_file" "created")
            if [[ -z "$brief_created" ]]; then
                info "BRIEF.md missing 'created' identity field"
            fi
        fi

        # --- Check STATUS.md size ---

        status_file="$ws_path/STATUS.md"
        if [[ -f "$status_file" ]]; then
            status_lines=$(count_content_lines "$status_file")
            if [[ "$status_lines" -gt 15 ]]; then
                warn "STATUS.md has $status_lines content lines (target: ≤10)"
                ((project_issues++)) || true
            fi
        fi

        # --- Check MEMORY.md size ---

        memory_file="$ws_path/MEMORY.md"
        if [[ -f "$memory_file" ]]; then
            memory_lines=$(wc -l < "$memory_file" | xargs)
            if [[ "$memory_lines" -gt 80 ]]; then
                warn "MEMORY.md has $memory_lines lines (hard limit: 80, target: ≤50)"
                ((project_issues++)) || true
            elif [[ "$memory_lines" -gt 50 ]]; then
                info "MEMORY.md has $memory_lines lines (approaching limit — target: ≤50, hard limit: 80)"
            fi
        fi

        # --- Check tick.md task tag ---

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
echo "Summary: $TOTAL_PROJECTS project(s), $TOTAL_WORKSTREAMS workstream(s), $TOTAL_ISSUES issue(s), $TOTAL_NOTES note(s)"

if [[ $TOTAL_ISSUES -gt 0 ]]; then
    echo "Status: ISSUES FOUND"
    exit 1
else
    echo "Status: ALL HEALTHY"
    exit 0
fi
