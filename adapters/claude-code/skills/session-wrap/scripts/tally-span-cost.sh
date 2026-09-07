#!/usr/bin/env bash
# tally-span-cost.sh — compute the token cost of a span of a Claude Code transcript.
#
# Usage:
#   tally-span-cost.sh <transcript.jsonl> [start_line] [end_line]
#
# start_line = 1-based line number to start AFTER (exclusive). 0/omitted = whole file.
# end_line   = 1-based last line to include. omitted = EOF.
#
# Sums usage across `assistant` messages in the range, groups by model, applies
# cost-pricing.json (sibling file, override with $COST_PRICING), and prints a JSON object:
#   { span:{...}, per_model:{...}, tokens:{...}, cost_usd:<number> }
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TRANSCRIPT="${1:?usage: tally-span-cost.sh <transcript> [start_line] [end_line]}"
START="${2:-0}"
END="${3:-}"
PRICING="${COST_PRICING:-$SCRIPT_DIR/cost-pricing.json}"

[ -f "$TRANSCRIPT" ] || { echo "no transcript: $TRANSCRIPT" >&2; exit 1; }
[ -f "$PRICING" ]    || { echo "no pricing file: $PRICING" >&2; exit 1; }

# Slice the line range, then aggregate + price entirely in jq.
if [ -n "$END" ]; then
  sed -n "$((START+1)),${END}p" "$TRANSCRIPT"
else
  sed -n "$((START+1)),\$p" "$TRANSCRIPT"
fi | jq -s --slurpfile p "$PRICING" --arg start "$START" --arg end "${END:-EOF}" '
  ($p[0]) as $price
  | ($price.models) as $m
  | ($price.fallback) as $fb
  | [ .[] | select(.type=="assistant") | {model: .message.model, u: .message.usage} ]
  | reduce .[] as $x ({};
      ($x.model // "unknown") as $mm
      | .[$mm] = ((.[$mm] // {input:0,output:0,cache_read:0,cache_write_5m:0,cache_write_1h:0,msgs:0})
        | .input          += ($x.u.input_tokens // 0)
        | .output         += ($x.u.output_tokens // 0)
        | .cache_read     += ($x.u.cache_read_input_tokens // 0)
        | .cache_write_5m += ($x.u.cache_creation.ephemeral_5m_input_tokens // 0)
        | .cache_write_1h += ($x.u.cache_creation.ephemeral_1h_input_tokens // 0)
        | .msgs           += 1))
  | to_entries
  | map(
      .key as $model | .value as $t
      | (($m[$model]) // $fb) as $r
      | {
          model: $model, msgs: $t.msgs,
          tokens: {input:$t.input, output:$t.output, cache_read:$t.cache_read, cache_write_5m:$t.cache_write_5m, cache_write_1h:$t.cache_write_1h},
          cost_usd: (
              $t.input          * $r.input          / 1000000
            + $t.output         * $r.output         / 1000000
            + $t.cache_read     * $r.cache_read     / 1000000
            + $t.cache_write_5m * $r.cache_write_5m / 1000000
            + $t.cache_write_1h * $r.cache_write_1h / 1000000
          )
        }
    )
  | { span: {start_line: ($start|tonumber), end_line: $end},
      per_model: map({(.model): {msgs,tokens,cost_usd}}) | add,
      tokens: (reduce .[] as $e ({input:0,output:0,cache_read:0,cache_write_5m:0,cache_write_1h:0};
                 .input+=$e.tokens.input | .output+=$e.tokens.output | .cache_read+=$e.tokens.cache_read
                 | .cache_write_5m+=$e.tokens.cache_write_5m | .cache_write_1h+=$e.tokens.cache_write_1h)),
      cost_usd: (map(.cost_usd) | add // 0) }
'
