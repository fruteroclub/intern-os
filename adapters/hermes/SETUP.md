# SETUP — Hermes Agent Adapter

*internOS v0.3.3 | 2026-05-07*

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

- `internos.workspace_path` — path to the internOS workspace where `projects/` lives. Default: `~/.hermes/workspace`.

Hermes injects this value into the skill payload at activation as a `[Skill config: ...]` block, so the agent always has the resolved absolute path. No need to hardcode the workspace location anywhere.

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

## Verification

- [ ] `hermes skills list | grep intern-os` shows the skill
- [ ] `which tick` returns a path
- [ ] Configured workspace exists with `projects/` directory
- [ ] At least one project initialized with `tick init`
- [ ] `/intern-os` activates in a session and the payload includes `[Skill config: internos.workspace_path = ...]`

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
