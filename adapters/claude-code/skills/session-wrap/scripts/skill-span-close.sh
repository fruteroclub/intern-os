#!/usr/bin/env bash
# skill-span-close.sh — close a skill cost span opened by skill-span-start.sh.
# Call this from the skill's final step (e.g. session-wrap Step 6b).
#
# Usage: skill-span-close.sh <skill> <session_id> [transcript_path]
#   session_id + transcript_path are in the gbrain breadcrumb
#   (tail -1 ~/.claude/gbrain-session-queue.jsonl) if not passed.
#
# Tallies transcript from the recorded start line to EOF, appends one record to
# ~/.claude/cost-log.jsonl, prints a one-line human summary, removes the marker.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SKILL="${1:?usage: skill-span-close.sh <skill> <session_id> [transcript_path]}"
SESSION="${2:?need session_id}"
TRANSCRIPT="${3:-}"
STATE="$HOME/.claude/cost-span-active/${SESSION}__${SKILL}.json"
LOG="$HOME/.claude/cost-log.jsonl"

if [ -f "$STATE" ]; then
  START="$(jq -r '.start_line' "$STATE")"
  [ -n "$TRANSCRIPT" ] || TRANSCRIPT="$(jq -r '.transcript_path' "$STATE")"
else
  # No start marker (hook not wired, or skill invoked before install): cost whole session.
  START=0
  echo "warn: no start marker at $STATE — tallying whole transcript" >&2
fi
[ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ] || { echo "no transcript" >&2; exit 1; }

result="$("$SCRIPT_DIR/tally-span-cost.sh" "$TRANSCRIPT" "$START")"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

printf '%s\n' "$(jq -c -n --arg ts "$ts" --arg skill "$SKILL" --arg session "$SESSION" \
  --argjson r "$result" '{ts:$ts, skill:$skill, session_id:$session} + $r')" >> "$LOG"

# Human line for the wrap message.
printf '%s' "$result" | jq -r --arg skill "$SKILL" '
  "\($skill): $\(.cost_usd*100|round/100) " +
  "(in \(.tokens.input) / out \(.tokens.output) / cache-read \(.tokens.cache_read) / cache-write \(.tokens.cache_write_5m + .tokens.cache_write_1h) tok)"'

rm -f "$STATE"
