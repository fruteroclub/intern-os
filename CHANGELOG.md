# Changelog

## v2.1.0 — 2026-03-31

### New features

- **Project discovery:** New `Discover project: [name]` command creates a project with `PROJECT.md`, `tick init`, agent registration, and a communication thread. The agent asks 4 discovery questions (domain, exclusions, owner, archive condition).
- **PROJECT.md template:** New template at `assets/templates/project/PROJECT.md` — defines project identity with domain, owner, boundaries, success criteria, and active workstreams list.
- **Project-vs-workstream criterion:** Documented decision rule — a project groups work of the same domain over time; a workstream is a concrete sprint within that domain.
- **Project lifecycle:** Full lifecycle defined (discover → active → archive) with explicit archive condition in PROJECT.md.

### Updated files

- `adapters/hermes/SKILL.md` — v2.1.0: added `Discover project` command, project-vs-workstream criterion, project lifecycle
- `assets/WORKSTREAMS.md` — v2.1: added Project Discovery and project-vs-workstream sections, split lifecycle into project + workstream
- `references/en/PLAYBOOK.md` — v2.1: added Entry E (new project discovery)
- `references/en/FRAMEWORK.md` — v2.1: updated project layer to include PROJECT.md, expanded project lifecycle with discovery flow
- **Sync check script:** `scripts/sync-check.sh` — diagnostic tool that scans a workspace and reports mismatches: missing thread_ids, incomplete Slack IDs, missing workstream files, orphan directories without tick.md tasks. Platform-agnostic, report-only.
- **Checkpoint reminder script:** `scripts/checkpoint-reminder.sh` — detects active workstreams with stale STATUS.md files. Configurable threshold (default 3 days). Cron-compatible exit codes.

## v2.0.0 — 2026-03-30

### Breaking changes

- **Project container:** Workstreams now live inside projects (`projects/[name]/workstreams/`) instead of a flat `workstreams/` directory. Existing workstream directories must be moved into a project.
- **SKILL.md moved:** Root `SKILL.md` moved to `adapters/openclaw/SKILL.md`. OpenClaw users should update their skill reference.
- **Thread ID format:** `discord_thread_id` in BRIEF.md replaced by `thread_id: [platform]:[id]` (e.g., `thread_id: discord:123456789`).

### New features

- **Agent-framework agnostic:** Adapters for OpenClaw, Hermes Agent, Claude Code, and a generic fallback. Core spec is agent-neutral.
- **tick.md integration:** TICK.md at project root as the default task management layer. Full coordination protocol with claim/release cycle. Project template includes pre-configured TICK.md and .tick/config.yml.
- **Multi-platform communication:** Discord forums and Slack threads as first-class platforms. Platform-agnostic communication protocol in COMMUNICATION.md.
- **Project templates:** `assets/templates/project/` (TICK.md + .tick/config.yml + workstreams/) and `assets/templates/workstream/` (6 files with headers and stubs).
- **Workspace layout example:** `examples/workspace-layout.md` showing a fully populated v2 workspace.

### Migration from v1

1. Create a project directory and move workstreams into it:
   ```bash
   mkdir -p projects/my-project
   mv workstreams/ projects/my-project/workstreams/
   ```
2. Initialize tick.md in the project:
   ```bash
   cd projects/my-project
   tick init
   tick agent register @agent-name --type bot --role engineer
   ```
3. Replace root WORKSTREAMS.md with the v2 version from `assets/WORKSTREAMS.md`
4. Update your agent configuration using the appropriate adapter (`adapters/[framework]/SETUP.md`)
5. Update `thread_id` in BRIEF.md files:
   - Old: `discord_thread_id: 123456789`
   - New: `thread_id: discord:123456789`
6. Create tasks in TICK.md for each active workstream:
   ```bash
   tick add "Workstream description" --tag workstream-name
   ```

## v1.0.0 — 2026-03-24

Initial release. OpenClaw + Discord only, flat workstreams directory, task management as external recommendation.
