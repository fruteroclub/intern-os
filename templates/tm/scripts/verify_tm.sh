#!/usr/bin/env bash
#
# verify_tm.sh — Portable internOS Transfer Module verifier.
#
# Zero runtime dependencies beyond POSIX utilities + sha256sum (Linux) or
# shasum -a 256 (macOS). Run from the TM root directory.
#
# Checks:
#   1. Required structural files present (SKILL.md, references/*, scripts/).
#   2. Required payload files present, based on declared TM type.
#   3. Forbidden patterns absent from payload (code/**, .env*, locks, etc.).
#   4. CHECKSUMS.sha256 verifies (if present).
#
# Exit codes:
#   0  TM verification OK
#   1  Structural or payload completeness failure
#   2  Forbidden file present in payload
#   3  Checksum mismatch
#   4  Usage / environment error

set -euo pipefail

# --- Locate TM root ---------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TM_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

# --- Pick sha256 utility ----------------------------------------------------

if command -v sha256sum >/dev/null 2>&1; then
    SHA256_CHECK="sha256sum -c"
elif command -v shasum >/dev/null 2>&1; then
    SHA256_CHECK="shasum -a 256 -c"
else
    echo "verify_tm: no sha256sum or shasum on PATH" >&2
    exit 4
fi

# --- Helpers ----------------------------------------------------------------

fail() {
    echo "TM verification FAILED: $1" >&2
    exit "$2"
}

# Extract a top-level scalar from TM.yml. Robust enough for the fields we
# need (name, type) — does NOT parse YAML structurally. For nested values
# (source.workspace, etc.) we use a path-prefix walk.
yaml_get() {
    local file="$1"
    local key="$2"
    awk -v k="$key" '
        $0 ~ "^[[:space:]]*" k "[[:space:]]*:" {
            sub(/^[^:]*:[[:space:]]*/, "", $0)
            gsub(/^["'\''[:space:]]+|["'\''[:space:]]+$/, "", $0)
            print
            exit
        }
    ' "$file"
}

# --- 1. Structural completeness --------------------------------------------

# Required files differ slightly by type. Read TM.yml type first so we know
# whether to require RETURN.md (snapshot types) or APPLY.md (engagement-delivery).
TM_YML_PRE="$TM_ROOT/references/TM.yml"
TM_TYPE_PRE=""
if [[ -f "$TM_YML_PRE" ]]; then
    TM_TYPE_PRE="$(yaml_get "$TM_YML_PRE" type)"
fi

REQUIRED_FILES=(
    SKILL.md
    README.md
    references/TM.yml
    references/IMPORT.md
    references/REDACTION_REPORT.md
    scripts/verify_tm.sh
)

case "$TM_TYPE_PRE" in
    internOS.engagement-delivery)
        REQUIRED_FILES+=(references/APPLY.md scripts/apply_to_target.sh)
        ;;
    *)
        REQUIRED_FILES+=(references/RETURN.md)
        ;;
esac

for f in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$TM_ROOT/$f" ]]; then
        fail "missing required file: $f" 1
    fi
done

# --- 2. Payload completeness per type --------------------------------------

TM_YML="$TM_ROOT/references/TM.yml"
TM_TYPE="$(yaml_get "$TM_YML" type)"

if [[ -z "$TM_TYPE" ]]; then
    fail "TM.yml: missing 'type' field" 1
fi

# Locate payload root: payload/<canonical_path>/. We don't trust author input
# beyond the structural shape — just find the first directory under payload/
# that contains PROJECT.md (project TM) or BRIEF.md (workstream TM).
PAYLOAD_DIR="$TM_ROOT/payload"
if [[ ! -d "$PAYLOAD_DIR" ]]; then
    fail "payload/ directory missing" 1
fi

case "$TM_TYPE" in
    internOS.project)
        REQUIRED_PAYLOAD=(PROJECT.md AGENTS.md TICK.md)
        ANCHOR=PROJECT.md
        ;;
    internOS.workstream)
        REQUIRED_PAYLOAD=(BRIEF.md STATUS.md)
        ANCHOR=BRIEF.md
        ;;
    internOS.engagement-delivery)
        # Different payload shape: payload/updates/ + payload/runtime/.
        # No anchor file inside a canonical_path subtree to locate.
        if [[ ! -d "$PAYLOAD_DIR/updates" ]]; then
            fail "engagement-delivery TM missing payload/updates/" 1
        fi
        if [[ ! -d "$PAYLOAD_DIR/runtime" ]]; then
            fail "engagement-delivery TM missing payload/runtime/" 1
        fi
        # Every content_path declared in TM.yml's updates block must exist.
        while IFS= read -r cp; do
            [[ -z "$cp" ]] && continue
            if [[ ! -f "$TM_ROOT/$cp" ]]; then
                fail "updates content_path missing: $cp" 1
            fi
        done < <(awk '
            /^updates:/ { in_b=1; next }
            in_b && /^[a-zA-Z_]+:/ && !/^[[:space:]]/ { in_b=0 }
            in_b && /^[[:space:]]+content_path:[[:space:]]*/ {
                sub(/^[[:space:]]+content_path:[[:space:]]*/, "")
                gsub(/^["'\''[:space:]]+|["'\''[:space:]]+$/, "")
                print
            }
        ' "$TM_YML")
        # If a runtime/mcp.json exists, validate it as JSON.
        if [[ -f "$PAYLOAD_DIR/runtime/mcp.json" ]]; then
            if command -v python3 >/dev/null 2>&1; then
                python3 -c "import json,sys; json.load(open('$PAYLOAD_DIR/runtime/mcp.json'))" 2>/dev/null \
                    || fail "payload/runtime/mcp.json is not valid JSON" 1
            fi
        fi
        ANCHOR=""   # Skip the anchor-based payload search below.
        ;;
    *)
        fail "unsupported TM type: $TM_TYPE (expected internOS.project, internOS.workstream, or internOS.engagement-delivery)" 1
        ;;
esac

# Find the canonical payload subdirectory by locating the anchor file (snapshot types only).
if [[ -n "$ANCHOR" ]]; then
    CANON_PAYLOAD="$(find "$PAYLOAD_DIR" -type f -name "$ANCHOR" 2>/dev/null | head -1)"
    if [[ -z "$CANON_PAYLOAD" ]]; then
        fail "payload anchor not found: expected $ANCHOR somewhere under payload/" 1
    fi
    CANON_DIR="$(dirname "$CANON_PAYLOAD")"

    for f in "${REQUIRED_PAYLOAD[@]}"; do
        if [[ ! -f "$CANON_DIR/$f" ]]; then
            fail "payload missing required file: $(basename "$CANON_DIR")/$f" 1
        fi
    done
fi

# --- 3. Forbidden patterns --------------------------------------------------

# Patterns are matched against the path *relative to the TM root* so the
# globs read naturally (e.g. `payload/.../code/foo.py`).
FORBIDDEN_PATTERNS=(
    '*/code/*'
    '*/.tick/lock'
    '*/.tick/session.json'
    '*/__pycache__/*'
    '*.pyc'
    '*/.env'
    '*/.env.*'
    '*/auth.json'
    '*.lock'
    '*.pid'
    '*/.internos-warnings'
    '*/SOUL.md'
    '*/memories/*'
    '*/sessions/*'
    '*/logs/*'
)

violations=()
while IFS= read -r -d '' p; do
    rel="${p#$TM_ROOT/}"
    for pat in "${FORBIDDEN_PATTERNS[@]}"; do
        # shellcheck disable=SC2053
        if [[ $rel == $pat ]]; then
            violations+=("$rel")
            break
        fi
    done
done < <(find "$PAYLOAD_DIR" -type f -print0)

if (( ${#violations[@]} > 0 )); then
    echo "TM verification FAILED: forbidden files present in payload" >&2
    for v in "${violations[@]}"; do
        echo "  $v" >&2
    done
    exit 2
fi

# --- 4. Checksums (optional but recommended) -------------------------------

if [[ -f "$TM_ROOT/CHECKSUMS.sha256" ]]; then
    if ! (cd "$TM_ROOT" && $SHA256_CHECK CHECKSUMS.sha256 >/dev/null 2>&1); then
        fail "CHECKSUMS.sha256 mismatch (run: cd $TM_ROOT && $SHA256_CHECK CHECKSUMS.sha256 to see details)" 3
    fi
else
    echo "TM verification WARN: no CHECKSUMS.sha256 present — integrity not verified" >&2
fi

echo "TM verification OK"
exit 0
