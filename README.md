# intern-os

internOS Workstreams skill for OpenClaw agents.

## Install

```
openclaw skills install https://github.com/fruteroclub/intern-os
```

That's it. The skill configures your agent to operate workstreams across Discord and filesystem automatically.

## What it does

Installs the **internOS Workstreams** framework — a coordination system where each active workstream exists in two places simultaneously:

- **Discord forum thread** — communication surface for humans and agents
- **Filesystem directory** — operational source of truth (`active-workstreams/[name]/`)

Agents loaded with this skill know how to:
- Activate a new workstream from any channel
- Load the right workstream context when entering a Discord thread
- Keep `STATUS.md` updated across sessions so context never gets lost

## After install

Run the setup assistant:

> Install internOS workstreams on this instance

The agent will copy `WORKSTREAMS.md` to your workspace root, add the internOS block to `AGENTS.md`, and create the `active-workstreams/` directory.

Restart your agent session once to activate.

## Built by

[Frutero](https://frutero.club) — Impact Technology for Latin America
