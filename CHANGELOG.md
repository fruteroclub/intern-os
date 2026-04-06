# Changelog

> **Version scheme:** internOS moved to `0.x.x` versioning starting with this release to reflect alpha status. Prior releases are kept as historical record.

## v0.2.2 — 2026-04-06

Addresses [#2](https://github.com/fruteroclub/intern-os/issues/2): Discord timeout-safe startup while preserving per-workstream context.

### Changes

- **Platform startup protocol (SKILL.md, all adapters):** ACK-first rule is now mandatory, not advisory. Replaces the loose "platform timeout protocol" note with an explicit startup mode table: Discord/Slack = LIGHT (ACK → BRIEF + STATUS → MEMORY on demand), Telegram/CLI = FULL.
- **MEMORY.md hygiene hardened:** Hard limit remains 80 lines; target ≤50 lines now documented. Rule clarified: curated summary only — detailed chronology must go in `docs/` notes, not MEMORY.md. Consolidation must happen before ending the session.
- **Version bump:** `2.1.0` → `0.2.2` across SKILL.md and all adapter SETUP.md files.

### Updated files

- `intern-os/SKILL.md` — v0.2.2: platform startup table, LIGHT mode contract, MEMORY.md hygiene rules
- `adapters/openclaw/SETUP.md` — v0.2.2: same platform startup table in AGENTS.md block
- `adapters/hermes/SETUP.md` — v0.2.2: Discord startup note added to Discord config section
- `adapters/generic/SETUP.md` — v0.2.2: platform modes in generic instructions block

---

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
- **MEMORY.md read limits:** Agents now read only the last 80 lines of MEMORY.md on startup. MEMORY.md must be maintained as a curated summary (≤80 lines), not a session log. Enforced across all adapters (Hermes, OpenClaw, Claude Code, generic).
- **STATUS.md size constraint:** STATUS.md must answer "where does this workstream stand?" in ≤10 lines.
- **Platform timeout protocol:** On platforms with short response timeouts (Discord ~2min, Slack ACK ~3s), agents must emit an acknowledgment before loading context files. Documented in WORKSTREAMS.md, PLAYBOOK.md, FRAMEWORK.md, and all adapters.
- **Repo restructure:** Skill content (SKILL.md, assets, references, scripts) moved into `intern-os/` subdirectory for out-of-the-box installation on both Hermes and OpenClaw. Unified SKILL.md replaces per-adapter SKILL.md files. Adapter SETUP.md files remain at `adapters/[framework]/`.
- **Uninstall guide:** All adapters + FRAMEWORK.md (en/es) now document uninstallation steps and workspace data model.

### Install commands (v2.1.0)

| Framework | Command |
|-----------|---------|
| Hermes Agent | `hermes skills install fruteroclub/intern-os/intern-os` |
| OpenClaw | `openclaw skills install https://github.com/fruteroclub/intern-os` |

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
