#!/usr/bin/env bash
#
# apply_to_target.sh — Apply an engagement-delivery TM's updates to its declared target project.
#
# Reads references/TM.yml from the TM root (parent of this script). For each
# entry in the `updates` block, applies the specified operation against the
# target file under the target project's canonical path.
#
# Mode follows apply_protocol.preferred in TM.yml. Falls back to staging-dir
# if target.repo is null or git is unavailable.
#
# Resolves the target canonical path by:
#   1. Splitting target.canonical_path into <workspace>/<rest>.
#   2. Looking up <workspace> in $INTERNOS_WORKSPACE (PATH-style, see the
#      Claude Code adapter's resolve-thread.sh for the same convention).
#   3. Joining <found-workspace-root>/<rest>.
#
# Exit codes:
#   0  applied successfully (or staged in staging-dir mode)
#   1  pre-apply check failed (TM invalid, target missing, etc.)
#   2  apply partially completed and stopped on error
#   3  usage / env error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TM_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"
TM_YML="$TM_ROOT/references/TM.yml"

if [[ ! -f "$TM_YML" ]]; then
    echo "apply: references/TM.yml not found at $TM_YML" >&2
    exit 1
fi

# --- Minimal YAML readers (only what we need) -------------------------------
#
# These don't parse YAML structurally — they pull specific scalar values from
# known top-level keys. Robust enough for the fields used here, and avoids a
# Python / yq dependency.

yaml_scalar() {
    # yaml_scalar <file> <dotted.path>
    # Supports paths like 'target.canonical_path' or 'apply_protocol.preferred'.
    local file="$1" path="$2"
    local depth=0 indent=""
    local IFS=. parts
    read -r -a parts <<< "$path"
    local current=""
    local key="${parts[0]}"
    local rest=("${parts[@]:1}")

    if (( ${#rest[@]} == 0 )); then
        awk -v k="$key" '
            $0 ~ "^[[:space:]]*" k "[[:space:]]*:" {
                sub(/^[^:]*:[[:space:]]*/, "", $0)
                gsub(/^["'\''[:space:]]+|["'\''[:space:]]+$/, "", $0)
                print
                exit
            }
        ' "$file"
        return
    fi

    # Nested: find the parent block, then read the child key within it.
    local parent="$key"
    local child_path="${rest[*]}"
    child_path="${child_path// /.}"

    awk -v p="$parent" -v c="$child_path" '
        BEGIN { in_block=0; base_indent=-1 }
        $0 ~ "^[[:space:]]*" p "[[:space:]]*:[[:space:]]*$" {
            match($0, /^[[:space:]]*/)
            base_indent = RLENGTH
            in_block = 1
            next
        }
        in_block {
            match($0, /^[[:space:]]*/)
            line_indent = RLENGTH
            # Skip blank lines
            if ($0 ~ /^[[:space:]]*$/) next
            if (line_indent <= base_indent) { in_block = 0; next }
            # We only handle one level of nesting here.
            if (split(c, ck, ".") == 1) {
                if ($0 ~ "^[[:space:]]+" c "[[:space:]]*:") {
                    sub(/^[^:]*:[[:space:]]*/, "", $0)
                    gsub(/^["'\''[:space:]]+|["'\''[:space:]]+$/, "", $0)
                    print
                    exit
                }
            }
        }
    ' "$file"
}

# Read the `updates:` block and emit ONE FIELD PER LINE in the fixed order:
#   target_file
#   op
#   section_title        (may be blank line if absent)
#   content_path
# Records are not separated — caller reads 4 lines at a time. This avoids
# IFS/separator quoting pitfalls when reading multi-line YAML values.
parse_updates() {
    awk '
        BEGIN { in_block=0; in_item=0 }
        /^updates:[[:space:]]*$/ { in_block=1; next }
        in_block && /^[a-zA-Z_]+:/ && !/^[[:space:]]/ {
            if (in_item) emit()
            in_block=0
            in_item=0
            next
        }
        in_block && /^[[:space:]]+-[[:space:]]+target_file:[[:space:]]*/ {
            if (in_item) emit()
            in_item=1
            tf=""; op=""; st=""; cp=""
            line=$0
            sub(/^[[:space:]]+-[[:space:]]+target_file:[[:space:]]*/, "", line)
            gsub(/^["'\''[:space:]]+|["'\''[:space:]]+$/, "", line)
            tf=line
            next
        }
        in_block && in_item && /^[[:space:]]+op:[[:space:]]*/ {
            line=$0; sub(/^[[:space:]]+op:[[:space:]]*/,"",line); gsub(/^["'\''[:space:]]+|["'\''[:space:]]+$/,"",line); op=line; next
        }
        in_block && in_item && /^[[:space:]]+section_title:[[:space:]]*/ {
            line=$0; sub(/^[[:space:]]+section_title:[[:space:]]*/,"",line); gsub(/^["'\''[:space:]]+|["'\''[:space:]]+$/,"",line); st=line; next
        }
        in_block && in_item && /^[[:space:]]+content_path:[[:space:]]*/ {
            line=$0; sub(/^[[:space:]]+content_path:[[:space:]]*/,"",line); gsub(/^["'\''[:space:]]+|["'\''[:space:]]+$/,"",line); cp=line; next
        }
        function emit() {
            printf "%s\n%s\n%s\n%s\n", tf, op, st, cp
        }
        END { if (in_item) emit() }
    ' "$TM_YML"
}

# --- Resolve target canonical path against $INTERNOS_WORKSPACE -------------

CANON_PATH="$(yaml_scalar "$TM_YML" target.canonical_path)"
if [[ -z "$CANON_PATH" ]]; then
    echo "apply: target.canonical_path missing in TM.yml" >&2
    exit 1
fi

# canonical_path is of the form: workspaces/<workspace-name>/projects/<project>[/...]
# We need to map <workspace-name> to an actual root via $INTERNOS_WORKSPACE.

if [[ -z "${INTERNOS_WORKSPACE:-}" ]]; then
    echo "apply: INTERNOS_WORKSPACE is not set (required to resolve target)" >&2
    exit 3
fi

# Strip leading "workspaces/" if present
rel="${CANON_PATH#workspaces/}"
ws_name="${rel%%/*}"
ws_rest="${rel#*/}"

TARGET_DIR=""
IFS=':' read -r -a _candidates <<< "$INTERNOS_WORKSPACE"
for c in "${_candidates[@]}"; do
    [[ -z "$c" ]] && continue
    [[ -d "$c" ]] || continue
    candidate_name="$(basename "$c")"
    if [[ "$candidate_name" == "$ws_name" ]]; then
        TARGET_DIR="$(cd "$c" && pwd -P)/$ws_rest"
        break
    fi
done

if [[ -z "$TARGET_DIR" || ! -d "$TARGET_DIR" ]]; then
    echo "apply: cannot resolve target canonical path '$CANON_PATH'" >&2
    echo "       looked for workspace '$ws_name' under \$INTERNOS_WORKSPACE entries" >&2
    exit 1
fi

echo "Target resolved: $TARGET_DIR"

# --- Pick apply mode --------------------------------------------------------

PREFERRED="$(yaml_scalar "$TM_YML" apply_protocol.preferred)"
PREFERRED="${PREFERRED:-staging-dir}"
TARGET_REPO="$(yaml_scalar "$TM_YML" target.repo)"
HAS_GIT=0
[[ -d "$TARGET_DIR/.git" ]] && HAS_GIT=1

MODE="$PREFERRED"
if [[ "$MODE" == "pr" || "$MODE" == "branch" ]]; then
    if [[ "$HAS_GIT" -ne 1 || -z "$TARGET_REPO" || "$TARGET_REPO" == "null" ]]; then
        echo "apply: requested mode '$MODE' but target has no git repo — falling back to staging-dir." >&2
        MODE="staging-dir"
    fi
fi

echo "Apply mode: $MODE"

# --- Apply ------------------------------------------------------------------

TM_NAME="$(yaml_scalar "$TM_YML" name)"
TM_NAME="${TM_NAME:-engagement-delivery}"
TS="$(date -u '+%Y%m%dT%H%M%SZ')"

if [[ "$MODE" == "pr" || "$MODE" == "branch" ]]; then
    BRANCH_PREFIX="$(yaml_scalar "$TM_YML" apply_protocol.branch_prefix)"
    BRANCH_PREFIX="${BRANCH_PREFIX:-tm/$TM_NAME/}"
    BRANCH="${BRANCH_PREFIX}${TS}"
    (cd "$TARGET_DIR" && git checkout -b "$BRANCH")
fi

DEST_BASE="$TARGET_DIR"
if [[ "$MODE" == "staging-dir" ]]; then
    STAGE_REL="$(yaml_scalar "$TM_YML" apply_protocol.staging_dir)"
    STAGE_REL="${STAGE_REL:-.tm-incoming/$TM_NAME/}"
    DEST_BASE="$TARGET_DIR/$STAGE_REL"
    mkdir -p "$DEST_BASE"
    echo "Staging directory: $DEST_BASE"
fi

count_applied=0
# Read 4 lines per record. parse_updates emits one field per line in fixed order.
while IFS= read -r target_file && \
      IFS= read -r op && \
      IFS= read -r section_title && \
      IFS= read -r content_path; do
    [[ -z "$target_file" ]] && continue
    src="$TM_ROOT/$content_path"
    if [[ ! -f "$src" ]]; then
        echo "apply: missing content file: $content_path" >&2
        exit 2
    fi
    dest="$DEST_BASE/$target_file"
    mkdir -p "$(dirname "$dest")"

    case "$op" in
        replace)
            cp "$src" "$dest"
            echo "  replace: $target_file"
            ;;
        create)
            if [[ -e "$dest" && "$MODE" != "staging-dir" ]]; then
                echo "apply: create op refuses existing file: $target_file" >&2
                exit 2
            fi
            cp "$src" "$dest"
            echo "  create:  $target_file"
            ;;
        append-section)
            {
                [[ -f "$dest" ]] && echo ""
                [[ -n "$section_title" ]] && echo "$section_title" && echo ""
                cat "$src"
            } >> "$dest"
            echo "  append:  $target_file ($section_title)"
            ;;
        merge)
            # Best-effort: append with a marker the receiver hand-merges.
            {
                echo ""
                echo "<!-- TM-MERGE-START: $(basename "$TM_ROOT") @ $TS -->"
                cat "$src"
                echo "<!-- TM-MERGE-END -->"
            } >> "$dest"
            echo "  merge:   $target_file (appended for hand-merge)"
            ;;
        *)
            echo "apply: unknown op '$op' for $target_file" >&2
            exit 2
            ;;
    esac
    count_applied=$((count_applied + 1))
done < <(parse_updates)

echo "Applied $count_applied update(s)."

if [[ "$MODE" == "pr" || "$MODE" == "branch" ]]; then
    (cd "$TARGET_DIR" && git add -A && git commit -m "tm($TM_NAME): apply engagement delivery

Generated by apply_to_target.sh from TM at $TM_ROOT.
Source: $(yaml_scalar "$TM_YML" source.project) (workspace $(yaml_scalar "$TM_YML" source.workspace))
Updates applied: $count_applied")
    if [[ "$MODE" == "pr" ]]; then
        echo ""
        echo "Branch committed. To open PR:"
        echo "  cd $TARGET_DIR && git push -u origin $BRANCH && gh pr create --fill"
    else
        echo ""
        echo "Branch committed. Push when ready: cd $TARGET_DIR && git push -u origin $BRANCH"
    fi
elif [[ "$MODE" == "staging-dir" ]]; then
    echo ""
    echo "Proposed changes staged at: $DEST_BASE"
    echo "Review with: ls -la $DEST_BASE"
    echo "To accept, copy or git apply manually; or git init the target and re-run in pr mode."
fi

exit 0
