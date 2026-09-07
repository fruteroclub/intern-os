---
name: checkpoint
repo: https://github.com/poktalabs/intern-os
metadata:
  version: 0.1.0
description: >-
  Fast, lightweight progress save before /compact or /clear. Explicit-invocation only
  (/checkpoint) — does NOT auto-fire on session-boundary phrases; that's /session-wrap's job.
  Updates internOS STATUS.md (and DECISIONS.md/TICK.md only if something concrete actually
  changed) or writes a CHECKPOINT.md snapshot outside internOS projects. Skips gbrain sync and
  journaling — those stay /session-wrap's job. Logs every run to ~/.claude/checkpoint-log.jsonl.
---

# checkpoint — fast progress save

A quick snapshot before compacting or clearing, not a session-end. No gbrain calls, no
journaling, no rich pickup doc — for that, use `/session-wrap`. Work through the steps in
order; steps 2-4 are conditional, skip what doesn't apply.

## Step 1 — Summarize

3-5 bullets, no padding: what's done this session, current state, next step.

## Step 2 — internOS files (conditional, scoped)

If `STATUS.md` exists under the active `workstreams/<name>/`:
- **Always** REPLACE its "current state" / "next" fields in place — never append a dated section.
  This is the routine case. If STATUS.md is already over ~40 lines, that's inherited bloat from a
  prior session skipping this rule; flag it to the user and suggest `/session-wrap` to do the
  `JOURNAL.md` split (checkpoint stays fast and doesn't do the split itself).
- **DECISIONS.md** — append one line (date, decision, why) only if a real load-bearing decision
  was made this session. Skip silently otherwise; don't manufacture a decision to log.
- **TICK.md** — only if a task's state actually changed. Guard first: `tick validate`; if it
  reports 0 tasks but the file has tasks, it's a lookalike — stop and flag rather than mutate.
  `tick done <id> <agent>` needs the agent arg.

## Step 3 — CHECKPOINT.md (non-internOS case)

If no internOS workstream is active, write/overwrite `./CHECKPOINT.md` in the cwd:

```markdown
# Checkpoint — <ISO date/time>
**State:** <1-2 sentences>
**Done:** <bullets>
**Next:** <bullets>
**Reference files:** <paths, if any>
```

Single snapshot file, not a history — `~/.claude/checkpoint-log.jsonl` (Step 5) is the history.

## Step 4 — Memory (conditional)

Only if something surfaced this session is durably worth keeping across *future* conversations
(a real decision, correction, or fact per the auto-memory rules) — save it. Skip silently if
nothing qualifies.

## Step 5 — Log + ask

### 5a. Verify the summary against what you wrote — BEFORE the closing message

Step 1's summary and Step 2/3's file updates come from the same reasoning, but the closing
message gets written last, from whatever is most salient in your head. **That drift always runs
one way: you restate what's already in STATUS.md / CHECKPOINT.md and present it as new.**

Grep what you just wrote for the facts you're about to surface:

```bash
grep -n "<term1>\|<term2>" <status-or-checkpoint-path>
```

- **Already there** → point at the file, don't repeat it.
- **Not there but the next session needs it** → put it in the FILE, then continue.
- **Neither** → session-local, drop it.

Never close with "a couple of things to remember for next time." **Chat does not survive a
`/clear` or a `/compact`; files do.** Anything that matters goes in the file — saying it in the
message is delivering it to the one channel that gets discarded, and it implies the file has
gaps it doesn't have.

### 5b. Log — this line is what the next session sees

Append one line to `~/.claude/checkpoint-log.jsonl`. The `SessionStart` hook
`~/.claude/hooks/latest-checkpoint-pointer.sh` renders a pointer from the newest entry that
carries a `checkpoint_path`. The hook hardcodes nothing — **to change what a future session
notices, change these fields, not the hook.**

```bash
printf '%s\n' "{\"ts\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"type\":\"checkpoint\",\"cwd\":\"$PWD\",\"project\":\"<project-or-null>\",\"workstream\":\"<workstream-or-null>\",\"checkpoint_path\":\"<absolute path, or omit>\",\"scope\":\"<what it covers>\",\"summary\":\"<one line>\"}" >> ~/.claude/checkpoint-log.jsonl
```

- Wrote a `CHECKPOINT.md` in Step 3 → log its absolute path as `checkpoint_path`.
- Only updated `STATUS.md` in Step 2 → **omit `checkpoint_path`.** A STATUS update is not a
  pick-up map, and pointing at one would displace a real `/session-wrap` checkpoint that is
  still the better cold-start entry. Omitting keeps the pointer accurate.
- `scope` — human-readable coverage, written to be read cold.
### 5c. Ask

Then one `AskUserQuestion`:
- **Compact** — tell the user to run `/compact`.
- **Clear** — tell the user to run `/clear`.

Recommend based on whether this is a natural stopping point; let the user decide.

---

For a full session-end (gbrain sync, journaling, rich pickup doc), use `/session-wrap` instead.
