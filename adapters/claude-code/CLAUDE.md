# internOS — Workstreams (Claude Code)

This project uses internOS. Workstreams live under
`$INTERNOS_WORKSPACE/projects/<project>/workstreams/<name>/` (default workspace:
`~/.hermes/workspace`). Each workstream is a long-running *thread*; each Claude
Code conversation is a *session* inside that thread. `/resume` continues the
thread with a new session.

## Thread resolution (do this first)

At the start of any turn that might touch a workstream, run:

```bash
~/.claude/skills/intern-os/scripts/resolve-thread.sh
```

- **Exit 0** → stdout is the active workstream's absolute path. Read its
  `BRIEF.md` and `STATUS.md` (in that order, in full). Escalate to
  `MEMORY.md` / `DECISIONS.md` / `STAKEHOLDERS.md` / `RESOURCES.md` only when
  the task requires it.
- **Exit 1** → no active workstream. The user is working outside any
  workstream subtree. Do nothing — don't search for one, don't load anything.
- **Exit 2** → a workstream directory was found but `BRIEF.md` is missing or
  its `thread_id` doesn't match the canonical
  `claude-code:projects/<project>/workstreams/<name>` form. Stop and ask the
  human. Do not silently fix the file.

Resolution is exact and deterministic. Never resolve a workstream by fuzzy
matching path fragments, similar names, or directory listings — if the
resolver doesn't return one, there isn't one.

## Operating protocol

Once resolved, follow the standard workstream protocol from the `intern-os`
skill: claim the tick.md task before working, update `STATUS.md` at session
end, consolidate `MEMORY.md` if it crosses 80 lines, append a session line to
`SESSIONS.md`, then `tick done` or `tick release`.

The full doctrine — resolution, runtime, recovery, isolation — lives in the
`intern-os` skill (`~/.claude/skills/intern-os/SKILL.md`). Load it when
operating on a workstream; don't duplicate it here.

## Cross-workstream lookups

For an operational overview of what's active across the workspace, consult
`$INTERNOS_WORKSPACE/projects/REGISTRY.md` (regenerate with
`generate-registry.sh`). Never use the registry to resolve a single
workstream — `BRIEF.md` is the authoritative binding.
