#!/usr/bin/env bash
#
# export-sessions.sh — Export a complete internOS project context for migration
# to another internOS-native host running the same setup.
#
# Bundles the four stores that track a project:
#   1. internOS repos    → git bundles (full history, incl. unpushed commits)
#                          + local-only journals/ (gitignored content substrate)
#   2. Claude Code        → ~/.claude/projects/<slug>/ (session transcripts + memory/)
#   3. gstack artifacts   → ~/.gstack/projects/*<name>*/ (plans, reviews, learnings)
#   4. gbrain memory      → markdown export of the project's pages + timeline
#
# Output: ONE bundle, encrypted with gpg AES-256 by default (transcripts can
# contain PHI/secrets). Pairs with import-sessions.sh on the target host.
#
# Usage:
#   export-sessions.sh <project-path> [--out <dir>] [--no-encrypt]
#
# Exit: 0 ok · 2 usage/precondition error.

set -euo pipefail

PROJECT_PATH="${1:-}"
if [ -z "$PROJECT_PATH" ]; then
  echo "usage: export-sessions.sh <project-path> [--out <dir>] [--no-encrypt]" >&2
  exit 2
fi
shift
OUT_DIR="$PWD"; ENCRYPT=1
while [ $# -gt 0 ]; do
  case "$1" in
    --out) mkdir -p "$2"; OUT_DIR="$(cd "$2" && pwd)"; shift 2;;
    --no-encrypt) ENCRYPT=0; shift;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

[ -d "$PROJECT_PATH" ] || { echo "✗ no such directory: $PROJECT_PATH" >&2; exit 2; }
PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"
PROJECT_NAME="$(basename "$PROJECT_PATH")"
[ -f "$PROJECT_PATH/PROJECT.md" ] || { echo "✗ not an internOS project (no PROJECT.md): $PROJECT_PATH" >&2; exit 2; }

TS="$(date +%Y%m%d-%H%M%S)"
WORKSPACES_ROOT="$HOME/workspaces"
# Claude Code names its per-project dir after the abs path with '/' → '-'.
CLAUDE_SLUG="$(printf '%s' "$PROJECT_PATH" | sed 's#/#-#g')"
# gbrain pages are slugged by workspace-relative path (e.g. poktalabs/projects/pokta-care).
GBRAIN_PREFIX="${PROJECT_PATH#"$WORKSPACES_ROOT"/}"

BUNDLE="${PROJECT_NAME}-context-${TS}"
STAGE="$(mktemp -d)/${BUNDLE}"
mkdir -p "$STAGE"/{repos,claude,gstack,gbrain}
log() { printf '  %s\n' "$*"; }

echo "▸ Exporting internOS project context: $PROJECT_NAME"
echo "  path: $PROJECT_PATH"

# ── 1. internOS repos → git bundles (+ local journals) ──────────────────────
echo "▸ [1/4] repos"
declare -a REPO_LINES=()   # name|remote|head|mode  (mode = bundled | clone)
# The internOS project repo is always bundled: it's small, may carry unpushed
# local commits, and makes the bundle self-contained (no GitHub needed to restore).
if git -C "$PROJECT_PATH" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git -C "$PROJECT_PATH" bundle create "$STAGE/repos/${PROJECT_NAME}.gitbundle" --all >/dev/null 2>&1
  log "bundled $PROJECT_NAME ($(git -C "$PROJECT_PATH" rev-parse --short HEAD))"
  REPO_LINES+=("$PROJECT_NAME|$(git -C "$PROJECT_PATH" remote get-url origin 2>/dev/null || echo '-')|$(git -C "$PROJECT_PATH" rev-parse HEAD)|bundled")
fi
# code/ subrepos are independent repos with their own remotes (some are large
# reference clones, e.g. medplum). Record remote+HEAD so the target clones them —
# only bundle a tree if the repo has NO remote (would otherwise be lost).
if [ -d "$PROJECT_PATH/code" ]; then
  for d in "$PROJECT_PATH"/code/*/; do
    [ -d "${d}.git" ] || continue
    name="$(basename "$d")"; repo="${d%/}"
    remote="$(git -C "$repo" remote get-url origin 2>/dev/null || echo '-')"
    head="$(git -C "$repo" rev-parse HEAD 2>/dev/null || echo '-')"
    if [ "$remote" = "-" ]; then
      git -C "$repo" bundle create "$STAGE/repos/${name}.gitbundle" --all >/dev/null 2>&1
      log "bundled $name (no remote — local-only)"
      REPO_LINES+=("$name|-|$head|bundled")
    else
      ahead="$(git -C "$repo" rev-list --count '@{u}..HEAD' 2>/dev/null || echo 0)"
      [ "${ahead:-0}" -gt 0 ] 2>/dev/null && log "⚠ $name has $ahead unpushed commit(s) — push before migrating (target clones from remote)"
      log "recorded $name → clone from $remote"
      REPO_LINES+=("$name|$remote|$head|clone")
    fi
  done
fi
# Local-only content substrate (journals/ is gitignored by the internOS allowlist).
( cd "$PROJECT_PATH" && find workstreams -type d -name journals 2>/dev/null ) > "$STAGE/.journals.list" || true
if [ -s "$STAGE/.journals.list" ]; then
  tar -C "$PROJECT_PATH" -czf "$STAGE/repos/local-journals.tar.gz" -T "$STAGE/.journals.list"
  log "captured $(wc -l < "$STAGE/.journals.list" | tr -d ' ') journals/ dir(s)"
fi
rm -f "$STAGE/.journals.list"

# ── 2. Claude Code sessions + memories ──────────────────────────────────────
echo "▸ [2/4] claude code"
CLAUDE_SRC="$HOME/.claude/projects/$CLAUDE_SLUG"
if [ -d "$CLAUDE_SRC" ]; then
  cp -R "$CLAUDE_SRC/." "$STAGE/claude/"
  log "transcripts: $(ls "$CLAUDE_SRC"/*.jsonl 2>/dev/null | wc -l | tr -d ' ') · memories: $(ls "$CLAUDE_SRC"/memory/*.md 2>/dev/null | wc -l | tr -d ' ')"
else
  log "(none at $CLAUDE_SRC)"
fi
printf '%s\n' "$CLAUDE_SLUG" > "$STAGE/claude/.source-slug"

# ── 3. gstack artifacts ─────────────────────────────────────────────────────
echo "▸ [3/4] gstack artifacts"
GSTACK_FOUND=0
for d in "$HOME"/.gstack/projects/*"$PROJECT_NAME"*/; do
  [ -d "$d" ] || continue
  cp -R "$d" "$STAGE/gstack/$(basename "$d")"
  log "$(basename "$d")"
  GSTACK_FOUND=$((GSTACK_FOUND+1))
done
[ "$GSTACK_FOUND" = 0 ] && log "(no matching ~/.gstack/projects/*$PROJECT_NAME*)"

# ── 4. gbrain memory (markdown, project-scoped, path-preserving) ────────────
echo "▸ [4/4] gbrain memory"
GBRAIN_N=0
if command -v gbrain >/dev/null 2>&1; then
  while IFS= read -r slug; do
    [ -z "$slug" ] && continue
    out="$STAGE/gbrain/pages/$slug.md"   # path-preserving so `gbrain import` reconstructs the slug
    mkdir -p "$(dirname "$out")"
    if gbrain get "$slug" > "$out" 2>/dev/null; then GBRAIN_N=$((GBRAIN_N+1)); fi
  done < <(gbrain list 2>/dev/null | awk '{print $1}' | grep -E "^${GBRAIN_PREFIX}(/|$)" || true)
  gbrain timeline "$GBRAIN_PREFIX/project" > "$STAGE/gbrain/timeline.txt" 2>/dev/null || true
  printf '%s\n' "$GBRAIN_PREFIX" > "$STAGE/gbrain/.source-prefix"
  log "exported $GBRAIN_N gbrain page(s) under $GBRAIN_PREFIX/"
else
  log "(gbrain CLI not on PATH — skipped)"
fi

# ── manifest + README ───────────────────────────────────────────────────────
{
  echo "{"
  echo "  \"schema\": \"internos-context-export/v1\","
  echo "  \"created\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
  echo "  \"project_name\": \"$PROJECT_NAME\","
  echo "  \"source\": {"
  echo "    \"host\": \"$(hostname)\", \"user\": \"$(whoami)\","
  echo "    \"project_path\": \"$PROJECT_PATH\","
  echo "    \"claude_slug\": \"$CLAUDE_SLUG\","
  echo "    \"gbrain_prefix\": \"$GBRAIN_PREFIX\","
  echo "    \"workspaces_root\": \"$WORKSPACES_ROOT\""
  echo "  },"
  echo "  \"repos\": ["
  for i in "${!REPO_LINES[@]}"; do
    IFS='|' read -r n r h m <<< "${REPO_LINES[$i]}"
    sep=,; [ "$i" = $((${#REPO_LINES[@]}-1)) ] && sep=
    echo "    {\"name\":\"$n\",\"remote\":\"$r\",\"head\":\"$h\",\"mode\":\"$m\"}$sep"
  done
  echo "  ],"
  echo "  \"gbrain_pages\": $GBRAIN_N,"
  echo "  \"tools\": {"
  echo "    \"gbrain\": \"$(gbrain --version 2>/dev/null | head -1 || echo unknown)\","
  echo "    \"node\": \"$(node --version 2>/dev/null || echo unknown)\","
  echo "    \"pnpm\": \"$(pnpm --version 2>/dev/null || echo unknown)\""
  echo "  }"
  echo "}"
} > "$STAGE/manifest.json"

cat > "$STAGE/README.md" <<EOF
# internOS context export — $PROJECT_NAME ($TS)

Whole-project context for migration to another internOS-native host.
Restore with: \`import-sessions.sh <this-bundle>\`

Contents:
- \`repos/\`   git bundles (full history) + local-journals.tar.gz
- \`claude/\`  ~/.claude/projects/<slug>/ — session transcripts + memory/
- \`gstack/\`  ~/.gstack/projects/<slug>/ — plans/reviews/learnings
- \`gbrain/pages/\`  project pages as markdown (re-imported with \`gbrain import\`)
- \`manifest.json\`  source host/paths/slugs/repos/tool versions

NOT included (re-provision on the target): repo secrets (.env*, gitignored),
credentials, API keys. Session transcripts MAY contain PHI — handle accordingly.
EOF

# ── pack + encrypt ──────────────────────────────────────────────────────────
echo "▸ packing"
mkdir -p "$OUT_DIR"
RAW="$OUT_DIR/$BUNDLE.tar.gz"
tar -C "$(dirname "$STAGE")" -czf "$RAW" "$(basename "$STAGE")"
rm -rf "$(dirname "$STAGE")"

if [ "$ENCRYPT" = 1 ]; then
  if command -v gpg >/dev/null 2>&1; then
    echo "▸ encrypting (gpg AES-256 — you'll be prompted for a passphrase; carry it to the target separately)"
    gpg --symmetric --cipher-algo AES256 --no-symkey-cache -o "$RAW.gpg" "$RAW"
    rm -f "$RAW"; FINAL="$RAW.gpg"
  elif command -v openssl >/dev/null 2>&1; then
    echo "▸ encrypting (openssl AES-256)"
    openssl enc -aes-256-cbc -pbkdf2 -salt -in "$RAW" -out "$RAW.enc"
    rm -f "$RAW"; FINAL="$RAW.enc"
  else
    echo "  ! no gpg/openssl — leaving UNENCRYPTED (contains PHI/secrets): $RAW" >&2
    FINAL="$RAW"
  fi
else
  FINAL="$RAW"
fi

echo
echo "✓ exported: $FINAL"
echo "  size: $(du -h "$FINAL" | cut -f1)"
echo "  copy it to the target host, then: import-sessions.sh \"$(basename "$FINAL")\""
