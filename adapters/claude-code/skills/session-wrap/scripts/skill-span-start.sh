#!/usr/bin/env bash
# skill-span-start.sh — PreToolUse hook. When the Skill tool is invoked for a skill
# we want to cost, record the transcript line count at that moment as the span start.
#
# Wire in settings.json under PreToolUse with matcher "Skill". Reads the hook JSON
# on stdin (tool_name, tool_input.skill, transcript_path, session_id).
#
# State: ~/.claude/cost-span-active/<session_id>__<skill>.json  (start marker)
# Never blocks the tool call — always exits 0.
set -euo pipefail

# Skills to cost. Add names here (space-separated) to track more.
TRACK="${COST_TRACK_SKILLS:-session-wrap}"

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || exit 0

skill="$(printf '%s' "$payload"   | jq -r '.tool_input.skill // empty' 2>/dev/null || true)"
tool="$(printf '%s' "$payload"    | jq -r '.tool_name // empty'        2>/dev/null || true)"
transcript="$(printf '%s' "$payload" | jq -r '.transcript_path // empty' 2>/dev/null || true)"
session="$(printf '%s' "$payload" | jq -r '.session_id // empty'      2>/dev/null || true)"

[ "$tool" = "Skill" ] || exit 0
[ -n "$skill" ] || exit 0
case " $TRACK " in *" $skill "*) : ;; *) exit 0 ;; esac
[ -f "$transcript" ] || exit 0

start_line="$(wc -l < "$transcript" | tr -d ' ')"
dir="$HOME/.claude/cost-span-active"
mkdir -p "$dir"
printf '{"session_id":"%s","skill":"%s","transcript_path":"%s","start_line":%s,"start_ts":"%s"}\n' \
  "$session" "$skill" "$transcript" "$start_line" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  > "$dir/${session}__${skill}.json"

exit 0
