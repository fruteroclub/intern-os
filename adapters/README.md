# Adapters — Agent Framework Integrations

internOS is agent-framework agnostic. The core specification (FRAMEWORK.md, PLAYBOOK.md, COMMUNICATION.md, TICK-INTEGRATION.md) defines the protocol. Adapters translate the protocol into each agent framework's native configuration format.

---

## What an adapter provides

Each adapter contains:

1. **Skill/instruction file** — the agent's native format for loading internOS instructions (e.g., SKILL.md for OpenClaw, CLAUDE.md for Claude Code)
2. **Setup guide** — framework-specific steps for installing and configuring internOS

---

## Adapter contract

Regardless of framework, the adapter must configure the agent to:

1. **Read `WORKSTREAMS.md`** at the start of any session in a workstream thread
2. **Follow the project → workstream → task hierarchy** (`projects/[name]/workstreams/[name]/`)
3. **Load only the active workstream** — not all workstreams
4. **Read workstream context** before working: BRIEF.md → STATUS.md → MEMORY.md
5. **Claim tasks in tick.md** before starting work: `tick claim TASK-X @agent-name`
6. **Update STATUS.md** at the end of every working session
7. **Release or complete tasks** in tick.md when done

---

## Available adapters

| Framework | Directory | Skill format |
|-----------|-----------|-------------|
| [OpenClaw](openclaw/) | `adapters/openclaw/` | SKILL.md + AGENTS.md block |
| [Hermes Agent](hermes/) | `adapters/hermes/` | SKILL.md (Hermes skill format) |
| [Claude Code](claude-code/) | `adapters/claude-code/` | CLAUDE.md (project instructions) |
| [Generic](generic/) | `adapters/generic/` | Manual setup for any agent |

---

## Writing a new adapter

To add support for a new agent framework:

1. Create a directory under `adapters/[framework-name]/`
2. Create the skill/instruction file in the framework's native format
3. Create a `SETUP.md` with framework-specific install and configuration steps
4. Ensure all 7 contract points above are covered
5. Add the framework to the table above and to the SETUP.md adapter table
