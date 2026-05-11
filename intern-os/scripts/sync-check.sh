#!/usr/bin/env bash
#
# sync-check.sh — internOS workspace health check (v0.3.1)
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
# Usage: bash sync-check.sh <workspace-path> [--rollout]
#        bash sync-check.sh --workstream <abs-path-to-workstream-dir>
#
#   --rollout     Append a prioritized rollout action list (workspace mode only)
#   --workstream  Check a single workstream directory and exit (no workspace walk).
#                 Findings printed as `LEVEL: message` lines to stdout for easy
#                 capture by hooks. Used by Claude Code's SessionEnd hook.
#
# Exit:  0 if all healthy, 1 if issues found, 2 on usage error

set -euo pipefail

# --- Args -------------------------------------------------------------------

WORKSPACE=""
ROLLOUT_MODE=false
WORKSTREAM_PATH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --rollout)
            ROLLOUT_MODE=true; shift ;;
        --workstream)
            if [[ $# -lt 2 ]]; then
                echo "Error: --workstream requires a path argument" >&2
                exit 2
            fi
            WORKSTREAM_PATH="$2"; shift 2 ;;
        --*)
            echo "Unknown option: $1" >&2; exit 2 ;;
        *)
            if [[ -z "$WORKSPACE" ]]; then
                WORKSPACE="$1"
            else
                echo "Unexpected argument: $1" >&2; exit 2
            fi
            shift ;;
    esac
done

# Mutually exclusive: workstream mode OR workspace mode.
if [[ -n "$WORKSTREAM_PATH" && -n "$WORKSPACE" ]]; then
    echo "Error: --workstream is mutually exclusive with a workspace argument" >&2
    exit 2
fi
if [[ -n "$WORKSTREAM_PATH" && "$ROLLOUT_MODE" == "true" ]]; then
    echo "Error: --workstream and --rollout cannot be combined" >&2
    exit 2
fi
if [[ -z "$WORKSTREAM_PATH" && -z "$WORKSPACE" ]]; then
    cat >&2 <<'EOF'
Usage:
  sync-check.sh <workspace-path> [--rollout]
  sync-check.sh --workstream <abs-path-to-workstream-dir>

  --rollout     Append a prioritized rollout action list (workspace mode only)
  --workstream  Check a single workstream directory and exit
EOF
    exit 2
fi

# --- Workstream-scoped mode -------------------------------------------------
#
# Quick, focused check on a single workstream. Outputs findings as
# `LEVEL: message` lines (LEVEL is INFO or WARN) to make capture by hooks
# trivial. Exits 0 if clean, 1 if any WARN was emitted.

if [[ -n "$WORKSTREAM_PATH" ]]; then
    if [[ ! -d "$WORKSTREAM_PATH" ]]; then
        echo "Error: workstream path does not exist: $WORKSTREAM_PATH" >&2
        exit 2
    fi

    ws_path="$(cd "$WORKSTREAM_PATH" && pwd -P)"
    ws_name="$(basename "$ws_path")"
    ws_warnings=0

    EXPECTED_FILES=(BRIEF.md STATUS.md MEMORY.md DECISIONS.md STAKEHOLDERS.md RESOURCES.md)

    # Files present
    for f in "${EXPECTED_FILES[@]}"; do
        if [[ ! -f "$ws_path/$f" ]]; then
            echo "WARN: missing expected file: $f"
            ((ws_warnings++)) || true
        fi
    done

    # BRIEF identity + thread_id
    brief="$ws_path/BRIEF.md"
    if [[ -f "$brief" ]]; then
        thread_id=$(sed -n "s/^[* ]*thread_id[*:]*[[:space:]]*//p" "$brief" 2>/dev/null | head -1 | xargs)
        if [[ -z "$thread_id" ]]; then
            echo "WARN: BRIEF.md has no thread_id"
            ((ws_warnings++)) || true
        elif [[ ! "$thread_id" =~ ^[a-z-]+:.+ ]]; then
            echo "WARN: thread_id format invalid: '$thread_id' (expected platform:id)"
            ((ws_warnings++)) || true
        fi

        for field in project workstream owner created; do
            value=$(sed -n "s/^[* ]*${field}[*:]*[[:space:]]*//p" "$brief" 2>/dev/null | head -1 | xargs)
            if [[ -z "$value" ]]; then
                echo "INFO: BRIEF.md missing '${field}' identity field"
            fi
        done
    fi

    # STATUS.md size — flag if >15 content lines (≤10 by design)
    status_file="$ws_path/STATUS.md"
    if [[ -f "$status_file" ]]; then
        status_lines=$(grep -cve '^\s*$' -e '^\s*<!--' "$status_file" 2>/dev/null || echo "0")
        if [[ "$status_lines" -gt 15 ]]; then
            echo "WARN: STATUS.md has $status_lines content lines (target: ≤10)"
            ((ws_warnings++)) || true
        fi
    fi

    # STATUS.md staleness — flag if unchanged ≥7 days (operational heartbeat)
    if [[ -f "$status_file" ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            status_mtime=$(stat -f %m "$status_file" 2>/dev/null || echo "0")
        else
            status_mtime=$(stat -c %Y "$status_file" 2>/dev/null || echo "0")
        fi
        now=$(date +%s)
        age_days=$(( (now - status_mtime) / 86400 ))
        if [[ "$age_days" -ge 7 ]]; then
            echo "INFO: STATUS.md unchanged for $age_days days — heartbeat is stale"
        fi
    fi

    # MEMORY.md size — hard limit 80, target ≤50
    memory_file="$ws_path/MEMORY.md"
    if [[ -f "$memory_file" ]]; then
        memory_lines=$(wc -l < "$memory_file" | xargs)
        if [[ "$memory_lines" -gt 80 ]]; then
            echo "WARN: MEMORY.md has $memory_lines lines (hard limit: 80, target: ≤50) — consolidate before adding more"
            ((ws_warnings++)) || true
        elif [[ "$memory_lines" -gt 50 ]]; then
            echo "INFO: MEMORY.md has $memory_lines lines (approaching limit — target: ≤50)"
        fi
    fi

    if [[ $ws_warnings -gt 0 ]]; then
        exit 1
    fi
    exit 0
fi

# --- Workspace mode (existing behavior) -------------------------------------

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

# Track all thread_ids to detect duplicates (bash 3.2 compatible — no assoc arrays)
SEEN_THREAD_IDS=""
SEEN_THREAD_OWNERS=""

# Rollout-specific tracking
ROLLOUT_UNBOUND=""
ROLLOUT_UNBOUND_COUNT=0
ROLLOUT_INCOMPLETE=""
ROLLOUT_INCOMPLETE_COUNT=0
ROLLOUT_MISSING_TAGS=""
ROLLOUT_MISSING_TAGS_COUNT=0

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
# Portable: no PCRE required.
extract_field() {
    local file="$1"
    local field="$2"
    sed -n "s/^[* ]*${field}[*:]*[[:space:]]*//p" "$file" 2>/dev/null \
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

if $ROLLOUT_MODE; then
    echo "internOS Sync Check (v0.3.1) — Rollout Mode"
else
    echo "internOS Sync Check (v0.3.1)"
fi
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
    project_shared_threads=false
    project_shared_platforms=""
    if [[ -f "$project_dir/PROJECT.md" ]]; then
        ok "PROJECT.md exists"

        # Read project-level shared-thread inbox opt-in (v0.4.0+).
        # When `shared_thread_ids: true`, duplicate thread_ids inside this
        # project are permitted for platforms listed in
        # `shared_thread_platforms` (comma-separated). Used for inbox-style
        # platforms (Telegram, WhatsApp, Signal, iMessage, etc.) where one
        # DM is the collaboration surface for multiple workstreams.
        sti=$(extract_field "$project_dir/PROJECT.md" "shared_thread_ids")
        if [[ "$sti" == "true" ]]; then
            project_shared_threads=true
            project_shared_platforms=$(extract_field "$project_dir/PROJECT.md" "shared_thread_platforms")
            info "shared-thread inbox project (platforms: ${project_shared_platforms:-<none specified>})"
        fi
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
                ROLLOUT_UNBOUND="${ROLLOUT_UNBOUND}${project_name}/${ws_name} → BRIEF.md
"
                ((ROLLOUT_UNBOUND_COUNT++)) || true
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

                    # Check for duplicate thread_ids (bash 3.2 compatible)
                    tid_key="$thread_id"
                    if echo "$SEEN_THREAD_IDS" | grep -qF "|$tid_key|" 2>/dev/null; then
                        dup_owner=$(echo "$SEEN_THREAD_OWNERS" | grep -F "|$tid_key|" | sed "s/.*|$tid_key|//" | sed 's/|.*//')
                        dup_project="${dup_owner%%/*}"

                        # Suppress the duplicate warning iff:
                        #   1) this project opts in (shared_thread_ids: true)
                        #   2) duplicate is within the SAME project
                        #   3) thread_id's platform is in shared_thread_platforms
                        # Otherwise warn as before.
                        suppress_duplicate=false
                        if $project_shared_threads \
                           && [[ "$dup_project" == "$project_name" ]] \
                           && [[ -n "$project_shared_platforms" ]] \
                           && [[ ",${project_shared_platforms// /}," == *",${platform},"* ]]; then
                            suppress_duplicate=true
                        fi

                        if $suppress_duplicate; then
                            info "thread_id ($thread_id) intentionally shared inside inbox project — also used by $dup_owner"
                        else
                            warn "thread_id ($thread_id) is duplicated — also used by $dup_owner"
                            ((project_issues++)) || true
                        fi
                    else
                        SEEN_THREAD_IDS="${SEEN_THREAD_IDS}|${tid_key}|"
                        SEEN_THREAD_OWNERS="${SEEN_THREAD_OWNERS}|${tid_key}|${project_name}/${ws_name}|"
                    fi
                else
                    warn "thread_id format invalid: '$thread_id' (expected platform:id)"
                    ((project_issues++)) || true
                    ROLLOUT_UNBOUND="${ROLLOUT_UNBOUND}${project_name}/${ws_name} → invalid format '${thread_id}'
"
                    ((ROLLOUT_UNBOUND_COUNT++)) || true
                fi
            fi

            # Identity fields (expected in BRIEF.md)
            brief_project=$(extract_field "$brief_file" "project")
            brief_ws=$(extract_field "$brief_file" "workstream")
            brief_owner=$(extract_field "$brief_file" "owner")
            brief_created=$(extract_field "$brief_file" "created")

            missing_identity=""
            if [[ -z "$brief_project" ]]; then
                info "BRIEF.md missing 'project' identity field"
                missing_identity="${missing_identity} project"
            fi
            if [[ -z "$brief_ws" ]]; then
                info "BRIEF.md missing 'workstream' identity field"
                missing_identity="${missing_identity} workstream"
            fi
            if [[ -z "$brief_owner" ]]; then
                info "BRIEF.md missing 'owner' identity field"
                missing_identity="${missing_identity} owner"
            fi
            if [[ -z "$brief_created" ]]; then
                info "BRIEF.md missing 'created' identity field"
                missing_identity="${missing_identity} created"
            fi
            if [[ -n "$missing_identity" ]]; then
                ROLLOUT_INCOMPLETE="${ROLLOUT_INCOMPLETE}${project_name}/${ws_name} → missing:${missing_identity}
"
                ((ROLLOUT_INCOMPLETE_COUNT++)) || true
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
                ROLLOUT_MISSING_TAGS="${ROLLOUT_MISSING_TAGS}${project_name}/${ws_name} → no task tagged '${ws_name}' in TICK.md
"
                ((ROLLOUT_MISSING_TAGS_COUNT++)) || true
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

if $ROLLOUT_MODE; then
    echo ""
    echo "========================================"
    echo "Rollout Priority List"
    echo "========================================"

    echo ""
    echo "--- Unbound workstreams (missing or invalid thread_id) ---"
    if [[ $ROLLOUT_UNBOUND_COUNT -gt 0 ]]; then
        n=1
        echo "$ROLLOUT_UNBOUND" | while IFS= read -r item; do
            [[ -z "$item" ]] && continue
            echo "  $n. $item"
            ((n++))
        done
    else
        echo "  (none)"
    fi

    echo ""
    echo "--- Incomplete identity fields ---"
    if [[ $ROLLOUT_INCOMPLETE_COUNT -gt 0 ]]; then
        n=1
        echo "$ROLLOUT_INCOMPLETE" | while IFS= read -r item; do
            [[ -z "$item" ]] && continue
            echo "  $n. $item"
            ((n++))
        done
    else
        echo "  (none)"
    fi

    echo ""
    echo "--- Missing TICK.md tags ---"
    if [[ $ROLLOUT_MISSING_TAGS_COUNT -gt 0 ]]; then
        n=1
        echo "$ROLLOUT_MISSING_TAGS" | while IFS= read -r item; do
            [[ -z "$item" ]] && continue
            echo "  $n. $item"
            ((n++))
        done
    else
        echo "  (none)"
    fi

    echo ""
    echo "Rollout summary: $ROLLOUT_UNBOUND_COUNT unbound, $ROLLOUT_INCOMPLETE_COUNT incomplete identity, $ROLLOUT_MISSING_TAGS_COUNT missing tags"
fi

if [[ $TOTAL_ISSUES -gt 0 ]]; then
    echo ""
    echo "Status: ISSUES FOUND"
    exit 1
else
    echo ""
    echo "Status: ALL HEALTHY"
    exit 0
fi
