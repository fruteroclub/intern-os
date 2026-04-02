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

| Framework | Command |
|-----------|---------|
| **Hermes Agent** | `hermes skills install fruteroclub/intern-os/intern-os` |
| **OpenClaw** | `openclaw skills install https://github.com/fruteroclub/intern-os` |
| **Claude Code** | Copy `adapters/claude-code/CLAUDE.md` to your project root |
| **Other** | See `adapters/generic/SETUP.md` |

After installing, follow your framework's setup guide in `adapters/[framework]/SETUP.md`.

## Scripts

| Script | What it does |
|--------|-------------|
| `intern-os/scripts/sync-check.sh` | Workspace health check — reports missing thread_ids, incomplete Slack IDs, missing files, orphan directories. Usage: `bash sync-check.sh <workspace-path>` |
| `intern-os/scripts/checkpoint-reminder.sh` | Stale STATUS.md detector — flags active workstreams not updated within threshold. Usage: `bash checkpoint-reminder.sh <workspace-path> [days]` |

## Documentation

| Document | What it covers |
|----------|---------------|
| `intern-os/references/en/FRAMEWORK.md` | Architecture — four layers, lifecycle, agent bootstrap |
| `intern-os/references/en/SETUP.md` | First-time setup guide |
| `intern-os/references/en/PLAYBOOK.md` | Day-to-day operations |
| `intern-os/references/en/TICK-INTEGRATION.md` | tick.md integration spec |
| `intern-os/references/en/COMMUNICATION.md` | Discord + Slack communication spec |

Spanish versions available in `intern-os/references/es/`.

## License

[AGPL v3](LICENSE) for open source use. Commercial license required for B2B products and SaaS — contact [hola@frutero.club](mailto:hola@frutero.club).

## Built by

[Frutero](https://frutero.club) — Impact Technology for Latin America
