# intern-os

internOS Workstreams framework — coordinate work across projects, tasks, communication threads, and filesystem workstreams for any AI agent framework.

## What it does

Installs the **internOS Workstreams** framework — a coordination system where each active workstream exists in four synchronized layers:

| Layer | Tool | Role |
|-------|------|------|
| **Project** | Filesystem (`projects/[name]/`) | Organizational container |
| **Management** | tick.md (`TICK.md`) | Task tracking and coordination |
| **Communication** | Discord forums · Slack threads | Human and agent collaboration |
| **Operation** | Filesystem (`workstreams/`) | Source of truth for agents |

Agents loaded with this framework know how to:
- Create and manage projects with tick.md task tracking
- Activate workstreams from any communication thread
- Load the right workstream context when entering a thread
- Claim tasks before working and release them when done
- Keep STATUS.md updated across sessions so context never gets lost

## Install

Choose the adapter for your agent framework:

| Framework | Install guide |
|-----------|---------------|
| **OpenClaw** | `adapters/openclaw/SETUP.md` |
| **Hermes Agent** | `adapters/hermes/SETUP.md` |
| **Claude Code** | `adapters/claude-code/SETUP.md` |
| **Other** | `adapters/generic/SETUP.md` |

For OpenClaw, you can also install as a skill:

```
openclaw skills install https://github.com/fruteroclub/intern-os
```

## Documentation

| Document | What it covers |
|----------|---------------|
| `references/en/FRAMEWORK.md` | Architecture — four layers, lifecycle, agent bootstrap |
| `references/en/SETUP.md` | First-time setup guide |
| `references/en/PLAYBOOK.md` | Day-to-day operations |
| `references/en/TICK-INTEGRATION.md` | tick.md integration spec |
| `references/en/COMMUNICATION.md` | Discord + Slack communication spec |

Spanish versions available in `references/es/`.

## License

[AGPL v3](LICENSE) for open source use. Commercial license required for B2B products and SaaS — contact [hola@frutero.club](mailto:hola@frutero.club).

## Built by

[Frutero](https://frutero.club) — Impact Technology for Latin America
