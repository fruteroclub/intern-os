# SETUP — Hermes Agent Adapter

*internOS v0.5.0 | 2026-06-18*

Hermes Agent-specific setup for the internOS Workstreams framework.

---

## Prerequisites

- Hermes Agent installed and running
- `tick-md` CLI on PATH: `npm install -g tick-md`
- At least one platform configured (Telegram, Slack, Discord, etc.)

---

## Install

```bash
hermes skills install fruteroclub/intern-os/intern-os
```

For development, symlink instead:

```bash
ln -s [intern-os-repo]/intern-os ~/.hermes/skills/intern-os
```

### Hermes security scan

Hermes' installer runs a security scan that flags intern-os as **DANGEROUS** with ~58 `agent_config_mod` findings. These are **expected false positives**: the scanner regex matches any literal mention of `AGENTS.md` / `CLAUDE.md`, and intern-os documents `AGENTS.md` extensively as a load-bearing project-context convention. The skill does not modify your AGENTS.md or CLAUDE.md files.

Use `--force` to override:

```bash
hermes skills install fruteroclub/intern-os/intern-os --force
```

Tracked upstream at [nousresearch/hermes-agent](https://github.com/nousresearch/hermes-agent) — once the scanner regex tightens to flag write/append patterns instead of any literal mention, `--force` will no longer be required.

---

## Configure

Run `hermes setup` (or edit `~/.hermes/config.yaml`) and set:

- `internos.workspace_path` — path to **either** a single internOS workspace (a directory that directly contains `projects/`) **or** a workspaces container (a directory whose immediate children are each workspaces). Default: `~/.hermes/workspace`.

Hermes injects this value into the skill payload at activation as a `[Skill config: ...]` block, so the agent always has the resolved absolute path. No need to hardcode the workspace location anywhere.

> **Note (Hermes config layout):** the value Hermes injects is read from `skills.config.internos.workspace_path`. A bare top-level `internos.workspace_path` key is **not** read by Hermes — keep the value under `skills.config`.

### Workspaces container (serve multiple workspaces from one gateway)

Point `internos.workspace_path` at a **workspaces container** — canonically a directory named `workspaces` (e.g. `~/.hermes/workspaces`, `~/workspaces`) — to let one Hermes gateway operate across several independent workspaces:

```text
~/.hermes/workspaces/          ← container (internos.workspace_path)
├── agencia/   └── projects/…  ← workspace
├── frutero/   └── projects/…  ← workspace
└── poktalabs/ └── projects/…  ← workspace
```

Detection is **structural**: if the configured path has its own `projects/` it is a single workspace; otherwise, if its immediate children each contain `projects/`, it is a container. The agent resolves a thread by exact `thread_id` across `<container>/*/projects/*/workstreams/*/BRIEF.md` — `thread_id` is globally unique, so the match is authoritative regardless of which workspace it lives in. Isolation still holds: a container groups independent workspaces, it does not merge them. New projects/workstreams are always created **inside a chosen child workspace**, never at the container root.

`sync-check.sh` and `generate-registry.sh` both accept a container path (see their `--help`/header docs).

---

## Initialize the workspace

```bash
WORKSPACE=~/.hermes/workspace   # or whatever you configured above
mkdir -p "$WORKSPACE/projects/"
cd "$WORKSPACE/projects/"
mkdir my-project && cd my-project
tick init
tick agent register @bot --type bot --role engineer
```

> The `WORKSTREAMS.md` runtime guide is auto-listed as a supporting file when intern-os activates — no manual copy required.

---

## Activate

In any thread, type `/intern-os` to load the skill explicitly. Hermes auto-registers a slash command for every installed skill from its `name:` field.

To preload on every session, add to `~/.hermes/config.yaml`:

```yaml
agent:
  preloaded_skills:
    - intern-os
```

---

## Slack thread-only mode (optional)

Add to `~/.hermes/.env`:

```bash
SLACK_BOT_TOKEN=xoxb-your-bot-token
SLACK_REQUIRE_MENTION=true
SLACK_FREE_RESPONSE_CHANNELS=ops-workstreams,tech-workstreams,ceo-workstreams
```

In `~/.hermes/config.yaml`:

```yaml
platforms:
  slack:
    enabled: true
    token: "${SLACK_BOT_TOKEN}"
    reply_to_mode: "first"
```

> `SLACK_FREE_RESPONSE_CHANNELS` lets the agent respond without `@mention` in workstream channels. The agent still responds only in threads, never in channel root.

---

## Discord (optional)

In `~/.hermes/config.yaml`:

```yaml
platforms:
  discord:
    enabled: true
    token: "${DISCORD_TOKEN}"
```

Forum channels named `*-workstreams` work natively as workstream threads. The agent emits ACK before any file reads (LIGHT mode) — see `intern-os/SKILL.md` for the platform startup table.

---

## Isolated-session handoff

When the coordinator delegates to an isolated Hermes subagent, use the handoff manifest layer per `references/en/ISOLATED-HANDOFF.md`.

**Hermes-specific wiring:**

- Native primitive: `delegate_task`. Spawns a fresh subagent with its own conversation state, terminal session, and tool access. The child does **not** inherit the parent transcript, memory, or active bindings.
- Coordinator writes the manifest to `<workstream_path>/handoffs/<handoff_id>.yml`.
- Coordinator passes the manifest **content** (not just the path) in `delegate_task.context`. The subagent may not have implicit filesystem access to the parent's cwd; embedding the manifest in context guarantees the specialist sees it.
- Subagent runs `bash <skill-dir>/scripts/verify-handoff.sh <manifest>` as its first action. Exit 3 aborts with the failing check name written to the return artifact.
- Output flows back two ways: the return artifact at `<workstream_path>/<artifact_path>`, plus the final summary the subagent returns to the coordinator.

**Optional Hermes manifest extensions** (top-level `hermes:` key, ignored by other adapters):

```yaml
hermes:
  acp_command: ""        # specific ACP-capable agent binary
  acp_args: []
  toolsets: []           # explicit toolset allowlist for the subagent
```

**Coordinator restriction recommendation:** scope the subagent's `toolsets` to file + terminal as needed for the task. Avoid granting network/external tools unless the task genuinely needs them.

---

## Verification

- [ ] `hermes skills list | grep intern-os` shows the skill
- [ ] `which tick` returns a path
- [ ] Configured path is either a workspace with `projects/`, or a container whose children have `projects/`
- [ ] At least one project initialized with `tick init`
- [ ] `/intern-os` activates in a session and the payload includes `[Skill config: internos.workspace_path = ...]`
- [ ] (container) `bash intern-os/scripts/sync-check.sh <container-path>` lists every child workspace

---

## Next step

Follow **PLAYBOOK.md** to activate your first workstream.

---

## Uninstall

```bash
hermes skills uninstall intern-os
```

To remove all project data (destructive — deletes all workstream files, task history, and accumulated context):

```bash
rm -rf ~/.hermes/workspace/projects/
```
