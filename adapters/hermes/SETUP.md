# SETUP — Hermes Agent Adapter

*internOS v2.1 | 2026-04-02*

Hermes Agent-specific setup for the internOS Workstreams framework.

---

## Prerequisites

- Hermes Agent installed and running (`~/.hermes/hermes-agent/`)
- Access to the Hermes workspace
- At least one platform configured (Telegram, Slack, Discord, etc.)

---

## Install the skill

```bash
hermes skills install fruteroclub/intern-os/intern-os
```

For development, symlink instead:

```bash
ln -s [intern-os-repo]/intern-os ~/.hermes/skills/intern-os
```

---

## Configure the workspace

### 1. Copy WORKSTREAMS.md

```bash
cp ~/.hermes/skills/intern-os/assets/WORKSTREAMS.md ~/.hermes/workspace/WORKSTREAMS.md
```

> Adjust the workspace path to match your Hermes configuration.

### 2. Create the projects directory

```bash
mkdir -p ~/.hermes/workspace/projects/
```

### 3. Initialize your first project

```bash
PROJECT=my-project
mkdir -p ~/.hermes/workspace/projects/$PROJECT
cd ~/.hermes/workspace/projects/$PROJECT
tick init
tick agent register @duki --type bot --role engineer
```

---

## Configure Slack thread-only mode

To use internOS with Slack, configure the Hermes gateway for thread-only operation in the workstreams channels:

### Environment variables

Add to `~/.hermes/.env`:

```bash
SLACK_BOT_TOKEN=xoxb-your-bot-token
SLACK_REQUIRE_MENTION=true
SLACK_FREE_RESPONSE_CHANNELS=ops-workstreams,tech-workstreams,ceo-workstreams
```

> `SLACK_FREE_RESPONSE_CHANNELS` enables the agent to respond without @mention in workstream channels. The agent still responds only in threads, not channel root.

### Gateway config

In `~/.hermes/config.yaml`, ensure Slack is enabled:

```yaml
platforms:
  slack:
    enabled: true
    token: "${SLACK_BOT_TOKEN}"
    reply_to_mode: "first"
```

---

## Configure Discord

For Discord, ensure the Hermes Discord adapter is configured with access to the `-workstreams` forums:

```yaml
platforms:
  discord:
    enabled: true
    token: "${DISCORD_TOKEN}"
```

No special forum configuration needed — Hermes handles Discord threads natively.

---

## Preload the skill

To have internOS loaded automatically, add it to the gateway start command or config:

```bash
python cli.py --gateway --skills intern-os
```

Or configure in `~/.hermes/config.yaml`:

```yaml
agent:
  preloaded_skills:
    - intern-os
```

---

## Restart the gateway

```bash
systemctl --user restart hermes-gateway
```

---

## Verification

- [ ] intern-os skill is in `~/.hermes/skills/`
- [ ] WORKSTREAMS.md exists in the workspace
- [ ] `projects/` directory exists
- [ ] At least one project initialized with tick.md
- [ ] Agent registered: `cd projects/[project] && tick agent list`
- [ ] Slack configured (if using Slack)
- [ ] Discord configured (if using Discord)
- [ ] Gateway restarted

---

## Next step

Follow **PLAYBOOK.md** to activate your first workstream.

---

## Uninstall

### 1. Remove the skill

```bash
hermes skills uninstall intern-os
```

Or manually:

```bash
rm -rf ~/.hermes/skills/intern-os/
```

### 2. Remove WORKSTREAMS.md from the workspace

```bash
rm ~/.hermes/workspace/WORKSTREAMS.md
```

### 3. Remove preload config and restart (only if preloaded)

If you added `intern-os` to `preloaded_skills` in `~/.hermes/config.yaml`, remove that entry and restart the gateway:

```bash
systemctl --user restart hermes-gateway
```

If intern-os was not preloaded (the default), no restart is needed — Hermes reads skills from disk per session.

### 4. (Optional) Remove workspace data

The steps above remove the internOS framework but **preserve your project data** (projects, workstreams, TICK.md, task history). To remove everything:

```bash
rm -rf ~/.hermes/workspace/projects/
```

> **Warning:** This deletes all project directories, workstream files, task history, and accumulated context. This cannot be undone.
