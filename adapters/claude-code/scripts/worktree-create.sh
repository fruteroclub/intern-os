#!/usr/bin/env bash
#
# worktree-create.sh — internOS WorktreeCreate hook for Claude Code.
#
# Claude Code's native worktree creation (`--worktree`, EnterWorktree,
# `isolation: worktree`) defaults to `<repo>/.claude/worktrees/<name>` and
# forks the repository the session was launched from. In an internOS project
# that session repo is the PROJECT repo, where `code/*` is gitignored — so a
# native worktree would fork the wrong repo and contain no code.
#
# This hook replaces that git logic (see
# https://code.claude.com/docs/en/worktrees#non-git-version-control):
# it reads the requested worktree name from the JSON on stdin, creates the
# worktree in the internOS canonical location `code/.worktrees/<name>/` as a
# linked worktree of a CODE repo via `worktree.sh`, and prints the created
# directory path to stdout (the contract: stdout = the session's new working
# directory; everything else goes to stderr).
#
# Target code repo resolution (a shared parking dir doesn't encode ownership):
#   1. $INTERNOS_WORKTREE_REPO if set
#   2. the sole code/<repo> if the project has exactly one
#   3. otherwise: error, asking the user to set $INTERNOS_WORKTREE_REPO
#
# Wire it in settings.json:
#   "hooks": { "WorktreeCreate": [ { "hooks": [ { "type": "command",
#     "command": "~/.claude/skills/intern-os/scripts/worktree-create.sh" } ] } ] }
#
# NOTE: because this hook replaces git logic, Claude Code does NOT process
# `.worktreeinclude` itself — `worktree.sh` performs that copy inside the hook.

set -euo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd -P)"
WORKTREE_SH="$SELF_DIR/worktree.sh"

log() { echo "worktree-create: $*" >&2; }

# --- Read the hook JSON payload from stdin; extract .name --------------------
PAYLOAD="$(cat)"
NAME=""
if command -v jq >/dev/null 2>&1; then
    NAME="$(printf '%s' "$PAYLOAD" | jq -r '.name // empty' 2>/dev/null || true)"
fi
if [[ -z "$NAME" ]]; then
    # jq-less fallback: pull the first "name":"..." value.
    NAME="$(printf '%s' "$PAYLOAD" | sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
fi
[[ -n "$NAME" ]] || { log "no worktree name on stdin; cannot create"; exit 1; }

# --- Resolve the project root (nearest ancestor containing code/) ------------
find_project_root() {
    local cur; cur="$(pwd -P)"
    while [[ "$cur" != "/" ]]; do
        [[ -d "$cur/code" ]] && { echo "$cur"; return 0; }
        cur="$(dirname "$cur")"
    done
    return 1
}
PROJECT_ROOT="$(find_project_root || true)"
[[ -n "$PROJECT_ROOT" ]] || { log "not inside an internOS project (no ancestor with code/)"; exit 1; }

# --- Resolve the target code repo -------------------------------------------
REPO="${INTERNOS_WORKTREE_REPO:-}"
if [[ -z "$REPO" ]]; then
    repos=()
    for d in "$PROJECT_ROOT"/code/*/; do
        d="${d%/}"
        [[ "$(basename "$d")" == ".worktrees" ]] && continue
        [[ -e "$d/.git" ]] && repos+=("$(basename "$d")")
    done
    if [[ ${#repos[@]} -eq 1 ]]; then
        REPO="${repos[0]}"
    elif [[ ${#repos[@]} -eq 0 ]]; then
        log "no code repos under $PROJECT_ROOT/code/"; exit 1
    else
        log "multiple code repos (${repos[*]}); set INTERNOS_WORKTREE_REPO to choose one"; exit 1
    fi
fi

# --- Delegate to worktree.sh; stdout must be ONLY the created dir path -------
DIR="$(bash "$WORKTREE_SH" create "$NAME" --repo "$REPO" --project "$PROJECT_ROOT")"
# worktree.sh prints only the worktree path to stdout; forward it verbatim.
printf '%s\n' "$DIR"
