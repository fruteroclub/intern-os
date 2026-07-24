#!/usr/bin/env bash
#
# generate-registry.sh — internOS workstream registry generator (v0.5.0)
#
# Scans all projects and workstreams in an internOS workspace, reads BRIEF.md
# and STATUS.md (canonical sources), and generates a derived registry at
# projects/REGISTRY.md.
#
# The registry is derived, never authoritative. BRIEF.md is the source of truth
# for thread-to-workstream binding. Re-run this script to refresh.
#
# The <workspace-path> may be a single workspace (contains projects/) OR a
# workspaces container (children are workspaces, canonically named
# "workspaces"). Given a container, a registry is generated per child
# workspace and a container-level index is written at <container>/REGISTRY.md.
#
# Usage: bash generate-registry.sh <workspace-path>
# Exit:  0 on success, 2 on usage error

set -euo pipefail

# --- Args -------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
    echo "Usage: generate-registry.sh <workspace-path>"
    echo "  e.g. generate-registry.sh ~/.hermes/workspace"
    exit 2
fi

WORKSPACE="$1"

# --- Container mode ---------------------------------------------------------
#
# Structural detection (matches sync-check.sh): a path with no projects/ of its
# own, but whose immediate children each contain projects/, is a workspaces
# container. Generate one registry per child workspace + a container index.

if [[ ! -d "$WORKSPACE/projects" ]]; then
    CONTAINER_WORKSPACES=()
    for child in "$WORKSPACE"/*/; do
        [[ -d "${child}projects" ]] && CONTAINER_WORKSPACES+=("${child%/}")
    done

    if [[ ${#CONTAINER_WORKSPACES[@]} -gt 0 ]]; then
        INDEX_FILE="$WORKSPACE/REGISTRY.md"
        TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')
        {
            echo "# Workspaces Container Registry"
            echo ""
            echo "> **Derived index — do not edit manually.** One row per workspace."
            echo "> Regenerate: \`bash intern-os/scripts/generate-registry.sh <container-path>\`"
            echo "> Generated: $TIMESTAMP"
            echo ""
            echo "| Workspace | Workstreams | Registry |"
            echo "|-----------|-------------|----------|"
        } > "$INDEX_FILE"

        for ws_root in "${CONTAINER_WORKSPACES[@]}"; do
            bash "$0" "$ws_root"
            ws_name=$(basename "$ws_root")
            # variable-depth: a project may be nested under a container
            # (projects/<container>/<child>/workstreams/<name>), not just
            # top-level (projects/<project>/workstreams/<name>)
            ws_count=$(find "$ws_root/projects" -type d -name workstreams 2>/dev/null \
                | while IFS= read -r wd; do find "$wd" -mindepth 1 -maxdepth 1 -type d; done \
                | grep -v '/archived' | wc -l | xargs)
            echo "| $ws_name | $ws_count | \`$ws_name/projects/REGISTRY.md\` |" >> "$INDEX_FILE"
        done

        echo "Container index generated: $INDEX_FILE (${#CONTAINER_WORKSPACES[@]} workspaces)"
        exit 0
    fi
fi

PROJECTS_DIR="$WORKSPACE/projects"
REGISTRY_FILE="$PROJECTS_DIR/REGISTRY.md"

if [[ ! -d "$PROJECTS_DIR" ]]; then
    echo "Error: $PROJECTS_DIR does not exist (and no immediate child contains projects/)"
    exit 2
fi

# --- Helpers -----------------------------------------------------------------

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

# --- State -------------------------------------------------------------------

TOTAL_PROJECTS=0
TOTAL_WORKSTREAMS=0
TOTAL_HEALTHY=0
TOTAL_INCOMPLETE=0
TOTAL_UNBOUND=0

EXPECTED_FILES=(BRIEF.md STATUS.md MEMORY.md DECISIONS.md STAKEHOLDERS.md RESOURCES.md)

# Row data arrays
declare -a ROW_PROJECT=()
declare -a ROW_WORKSTREAM=()
declare -a ROW_THREAD_ID=()
declare -a ROW_PHASE=()
declare -a ROW_OWNER=()
declare -a ROW_HEALTH=()
declare -a ROW_PATH=()
declare -a ROW_ISSUES=()

# --- Main scan ---------------------------------------------------------------

# A project's workstreams live directly under a `workstreams/` dir at any
# depth — `projects/<project>/workstreams/` (top-level) or
# `projects/<container>/<child-project>/workstreams/` (nested child project).
# `find -name workstreams` locates the project dir regardless of nesting depth;
# `project_name` is then everything between PROJECTS_DIR and that dir, so a
# nested project reads as `club/club-app` rather than just `club-app`.
while IFS= read -r -d '' ws_dir; do
    project_dir="$(dirname "$ws_dir")"
    project_name="${project_dir#$PROJECTS_DIR/}"

    # Skip archived projects
    [[ "$(basename "$project_dir")" == "archived" ]] && continue

    ((TOTAL_PROJECTS++)) || true

    for ws_path in "$ws_dir"/*/; do
        [[ -d "$ws_path" ]] || continue

        ws_name=$(basename "$ws_path")

        # Skip archived workstreams
        [[ "$ws_name" == "archived" ]] && continue

        ((TOTAL_WORKSTREAMS++)) || true

        # Relative path from workspace root
        rel_path="projects/$project_name/workstreams/$ws_name/"

        # --- Extract fields ---

        brief_file="$ws_path/BRIEF.md"
        status_file="$ws_path/STATUS.md"

        thread_id=""
        owner=""
        phase=""
        issues=()

        # From BRIEF.md
        if [[ -f "$brief_file" ]]; then
            thread_id=$(extract_field "$brief_file" "thread_id")
            owner=$(extract_field "$brief_file" "owner")

            if [[ -z "$thread_id" ]]; then
                issues+=("missing thread_id")
            elif [[ ! "$thread_id" =~ ^[a-z-]+:.+ ]]; then
                issues+=("invalid thread_id format")
            fi

            # Check identity fields
            brief_project=$(extract_field "$brief_file" "project")
            brief_ws=$(extract_field "$brief_file" "workstream")
            brief_created=$(extract_field "$brief_file" "created")
            [[ -z "$brief_project" ]] && issues+=("missing project field")
            [[ -z "$brief_ws" ]] && issues+=("missing workstream field")
            [[ -z "$owner" ]] && issues+=("missing owner field")
            [[ -z "$brief_created" ]] && issues+=("missing created field")
        else
            issues+=("BRIEF.md missing")
        fi

        # From STATUS.md
        if [[ -f "$status_file" ]]; then
            phase=$(extract_field "$status_file" "Phase")
        else
            issues+=("STATUS.md missing")
        fi

        # Check expected files
        missing_files=()
        for f in "${EXPECTED_FILES[@]}"; do
            if [[ ! -f "$ws_path/$f" ]]; then
                missing_files+=("$f")
            fi
        done
        if [[ ${#missing_files[@]} -gt 0 ]]; then
            issues+=("missing files: ${missing_files[*]}")
        fi

        # --- Determine health ---

        health="healthy"
        if [[ -z "$thread_id" || ! "$thread_id" =~ ^[a-z-]+:.+ ]]; then
            health="unbound"
            ((TOTAL_UNBOUND++)) || true
        elif [[ ${#issues[@]} -gt 0 ]]; then
            health="incomplete"
            ((TOTAL_INCOMPLETE++)) || true
        else
            ((TOTAL_HEALTHY++)) || true
        fi

        # --- Store row ---

        idx=${#ROW_PROJECT[@]}
        ROW_PROJECT[$idx]="$project_name"
        ROW_WORKSTREAM[$idx]="$ws_name"
        ROW_THREAD_ID[$idx]="${thread_id:-—}"
        ROW_PHASE[$idx]="${phase:-—}"
        ROW_OWNER[$idx]="${owner:-—}"
        ROW_HEALTH[$idx]="$health"
        ROW_PATH[$idx]="$rel_path"
        if [[ ${#issues[@]} -gt 0 ]]; then
            ROW_ISSUES[$idx]="$(IFS='; '; echo "${issues[*]}")"
        else
            ROW_ISSUES[$idx]=""
        fi
    done
done < <(find "$PROJECTS_DIR" -type d -name workstreams -print0)

# --- Generate REGISTRY.md ---------------------------------------------------

TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')

{
    cat <<HEADER
# Workstream Registry

> **Derived from BRIEF.md + STATUS.md — do not edit manually.**
> Regenerate: \`bash intern-os/scripts/generate-registry.sh <workspace-path>\`
> Generated: $TIMESTAMP

---

## Summary

| Metric | Count |
|--------|-------|
| Projects | $TOTAL_PROJECTS |
| Workstreams (non-archived) | $TOTAL_WORKSTREAMS |
| Healthy | $TOTAL_HEALTHY |
| Incomplete | $TOTAL_INCOMPLETE |
| Unbound | $TOTAL_UNBOUND |

---

## Workstreams

| Project | Workstream | Thread ID | Phase | Owner | Health | Path |
|---------|------------|-----------|-------|-------|--------|------|
HEADER

    for i in "${!ROW_PROJECT[@]}"; do
        echo "| ${ROW_PROJECT[$i]} | ${ROW_WORKSTREAM[$i]} | \`${ROW_THREAD_ID[$i]}\` | ${ROW_PHASE[$i]} | ${ROW_OWNER[$i]} | ${ROW_HEALTH[$i]} | \`${ROW_PATH[$i]}\` |"
    done

    # --- Unbound section ---

    has_unbound=false
    for i in "${!ROW_HEALTH[@]}"; do
        if [[ "${ROW_HEALTH[$i]}" == "unbound" ]]; then
            has_unbound=true
            break
        fi
    done

    if $has_unbound; then
        cat <<'UNBOUND_HEADER'

---

## Unbound Workstreams

Workstreams missing a valid `thread_id` in BRIEF.md — cannot be resolved by agents.

| Project | Workstream | Owner | Issues | Path |
|---------|------------|-------|--------|------|
UNBOUND_HEADER

        for i in "${!ROW_HEALTH[@]}"; do
            if [[ "${ROW_HEALTH[$i]}" == "unbound" ]]; then
                echo "| ${ROW_PROJECT[$i]} | ${ROW_WORKSTREAM[$i]} | ${ROW_OWNER[$i]} | ${ROW_ISSUES[$i]} | \`${ROW_PATH[$i]}\` |"
            fi
        done
    fi

    # --- Incomplete section ---

    has_incomplete=false
    for i in "${!ROW_HEALTH[@]}"; do
        if [[ "${ROW_HEALTH[$i]}" == "incomplete" ]]; then
            has_incomplete=true
            break
        fi
    done

    if $has_incomplete; then
        cat <<'INCOMPLETE_HEADER'

---

## Incomplete Workstreams

Workstreams with valid `thread_id` but missing files or identity fields.

| Project | Workstream | Issues | Path |
|---------|------------|--------|------|
INCOMPLETE_HEADER

        for i in "${!ROW_HEALTH[@]}"; do
            if [[ "${ROW_HEALTH[$i]}" == "incomplete" ]]; then
                echo "| ${ROW_PROJECT[$i]} | ${ROW_WORKSTREAM[$i]} | ${ROW_ISSUES[$i]} | \`${ROW_PATH[$i]}\` |"
            fi
        done
    fi

} > "$REGISTRY_FILE"

# --- Console output ----------------------------------------------------------

echo "Registry generated: $REGISTRY_FILE"
echo "  $TOTAL_PROJECTS project(s), $TOTAL_WORKSTREAMS workstream(s)"
echo "  $TOTAL_HEALTHY healthy, $TOTAL_INCOMPLETE incomplete, $TOTAL_UNBOUND unbound"
