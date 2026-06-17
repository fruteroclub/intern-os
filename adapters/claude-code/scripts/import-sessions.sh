#!/usr/bin/env bash
#
# import-sessions.sh — Restore an internOS project context exported by
# export-sessions.sh, on a target host running the same setup.
#
# Reconstitutes the four stores: internOS repos (from git bundles), Claude Code
# sessions/memories, gstack artifacts, and gbrain memory (re-imported markdown,
# re-embedded on this host). Path-derived slugs are remapped if the target
# project path differs from the source.
#
# Usage:
#   import-sessions.sh <bundle[.tar.gz|.gpg|.enc]> [--project-path <path>] [--dry-run]
#
# Default project path = the source path recorded in the manifest (same setup).
# Exit: 0 ok · 2 usage/precondition error.

set -euo pipefail

BUNDLE="${1:-}"
if [ -z "$BUNDLE" ]; then
  echo "usage: import-sessions.sh <bundle[.tar.gz|.gpg|.enc]> [--project-path <path>] [--dry-run]" >&2
  exit 2
fi
shift
TARGET_PATH=""; DRY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --project-path) TARGET_PATH="$2"; shift 2;;
    --dry-run) DRY=1; shift;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done
[ -f "$BUNDLE" ] || { echo "✗ no such file: $BUNDLE" >&2; exit 2; }
BUNDLE="$(cd "$(dirname "$BUNDLE")" && pwd)/$(basename "$BUNDLE")"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
run() { if [ "$DRY" = 1 ]; then echo "  [dry-run] $*"; else eval "$*"; fi; }

# ── decrypt + unpack ────────────────────────────────────────────────────────
echo "▸ unpacking $(basename "$BUNDLE")"
TARBALL="$WORK/bundle.tar.gz"
case "$BUNDLE" in
  *.gpg) gpg -d -o "$TARBALL" "$BUNDLE" ;;
  *.enc) openssl enc -d -aes-256-cbc -pbkdf2 -in "$BUNDLE" -out "$TARBALL" ;;
  *.tar.gz) cp "$BUNDLE" "$TARBALL" ;;
  *) echo "✗ unknown bundle extension (expect .gpg/.enc/.tar.gz)" >&2; exit 2;;
esac
tar -C "$WORK" -xzf "$TARBALL"
SRC="$(find "$WORK" -maxdepth 1 -type d -name '*-context-*' | head -1)"
[ -d "$SRC" ] || { echo "✗ bundle has no *-context-* root" >&2; exit 2; }
[ -f "$SRC/manifest.json" ] || { echo "✗ no manifest.json in bundle" >&2; exit 2; }

# ── read manifest (jq if present, else grep) ────────────────────────────────
mfield() {  # dotted path under .source, best-effort without jq
  if command -v jq >/dev/null 2>&1; then jq -r ".source.$1 // empty" "$SRC/manifest.json"
  else grep -oE "\"$1\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$SRC/manifest.json" | head -1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/'; fi
}
SRC_PATH="$(mfield project_path)"
SRC_CLAUDE_SLUG="$(mfield claude_slug)"
SRC_GBRAIN_PREFIX="$(mfield gbrain_prefix)"
PROJECT_NAME="$(basename "$SRC_PATH")"

TARGET_PATH="${TARGET_PATH:-$SRC_PATH}"
TARGET_PATH="$(cd "$(dirname "$TARGET_PATH")" 2>/dev/null && pwd || dirname "$TARGET_PATH")/$(basename "$TARGET_PATH")"
TARGET_CLAUDE_SLUG="$(printf '%s' "$TARGET_PATH" | sed 's#/#-#g')"

echo "  project : $PROJECT_NAME"
echo "  source  : $SRC_PATH"
echo "  target  : $TARGET_PATH"
[ "$TARGET_CLAUDE_SLUG" != "$SRC_CLAUDE_SLUG" ] && echo "  (remapping claude slug: $SRC_CLAUDE_SLUG → $TARGET_CLAUDE_SLUG)"
[ "$DRY" = 1 ] && echo "  -- DRY RUN: no changes will be written --"

# ── 1. repos (from git bundles) ─────────────────────────────────────────────
echo "▸ [1/4] repos"
restore_one() {  # <name> <remote> <mode> <dest>
  local name="$1" remote="$2" mode="$3" dest="$4" b="$SRC/repos/$1.gitbundle"
  if [ -e "$dest/.git" ]; then echo "  skip $name (exists at $dest)"; return 0; fi
  run "mkdir -p '$(dirname "$dest")'"
  if [ "$mode" = "bundled" ] && [ -f "$b" ]; then
    run "git clone --quiet '$b' '$dest'"
    # clone-from-bundle leaves origin = the bundle file; point it at the real remote
    [ "$remote" != "-" ] && [ "$DRY" = 0 ] && git -C "$dest" remote set-url origin "$remote" 2>/dev/null || true
    echo "  restored $name (bundle) → $dest"
  elif [ "$remote" != "-" ]; then
    run "git clone --quiet '$remote' '$dest'"
    echo "  cloned $name from $remote → $dest"
  else
    echo "  ⚠ $name: no bundle and no remote — skipped"
  fi
}
if command -v jq >/dev/null 2>&1; then
  while IFS=$'\t' read -r n rem mode; do
    dest="$TARGET_PATH"; [ "$n" != "$PROJECT_NAME" ] && dest="$TARGET_PATH/code/$n"
    restore_one "$n" "$rem" "$mode" "$dest"
  done < <(jq -r '.repos[] | [.name,.remote,.mode] | @tsv' "$SRC/manifest.json")
else
  echo "  (jq missing — restoring bundled repos only; clone-mode repos must be git-cloned manually)"
  for b in "$SRC"/repos/*.gitbundle; do
    [ -f "$b" ] || continue; n="$(basename "$b" .gitbundle)"
    dest="$TARGET_PATH"; [ "$n" != "$PROJECT_NAME" ] && dest="$TARGET_PATH/code/$n"
    restore_one "$n" "-" "bundled" "$dest"
  done
fi
# local journals
if [ -f "$SRC/repos/local-journals.tar.gz" ]; then
  run "tar -C '$TARGET_PATH' -xzf '$SRC/repos/local-journals.tar.gz'"
  echo "  restored local journals/"
fi

# ── 2. Claude Code sessions + memories ──────────────────────────────────────
echo "▸ [2/4] claude code"
CLAUDE_DEST="$HOME/.claude/projects/$TARGET_CLAUDE_SLUG"
if [ -d "$SRC/claude" ] && [ -n "$(ls -A "$SRC/claude" 2>/dev/null)" ]; then
  run "mkdir -p '$CLAUDE_DEST'"
  run "cp -R '$SRC/claude/.' '$CLAUDE_DEST/'"
  run "rm -f '$CLAUDE_DEST/.source-slug'"
  echo "  → $CLAUDE_DEST"
else
  echo "  (no claude data in bundle)"
fi

# ── 3. gstack artifacts ─────────────────────────────────────────────────────
echo "▸ [3/4] gstack artifacts"
if [ -d "$SRC/gstack" ] && [ -n "$(ls -A "$SRC/gstack" 2>/dev/null)" ]; then
  for d in "$SRC"/gstack/*/; do
    [ -d "$d" ] || continue
    run "mkdir -p '$HOME/.gstack/projects/$(basename "$d")'"
    run "cp -R '$d.' '$HOME/.gstack/projects/$(basename "$d")/'"
    echo "  $(basename "$d")"
  done
else
  echo "  (none)"
fi

# ── 4. gbrain memory ────────────────────────────────────────────────────────
echo "▸ [4/4] gbrain memory"
if [ -d "$SRC/gbrain/pages" ] && command -v gbrain >/dev/null 2>&1; then
  run "gbrain import '$SRC/gbrain/pages'"
  echo "  imported gbrain pages (re-embedded on this host)"
  [ -f "$SRC/gbrain/timeline.txt" ] && echo "  note: timeline view in gbrain/timeline.txt (re-add entries with 'gbrain timeline-add' if needed)"
else
  echo "  (no gbrain pages or gbrain CLI missing)"
fi

echo
echo "✓ import complete${DRY:+ (dry-run)}"
echo "  Next on this host:"
echo "   • Re-provision secrets NOT in the bundle: code/*/.env.local (NEBIUS/PRIVY/DB/etc.)."
echo "   • Verify: gbrain query \"$PROJECT_NAME\"  ·  ls '$CLAUDE_DEST'  ·  git -C '$TARGET_PATH' log --oneline -1"
echo "   • Open the workstream: cd into it so the intern-os skill auto-loads STATUS/BRIEF."
