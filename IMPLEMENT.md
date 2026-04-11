# Implement internOS on This Agent

You are setting up the internOS Workstreams framework on this Hermes Agent instance. internOS coordinates work across three layers: storage (workstream files as source of truth), resolution (exact thread_id binding), and runtime (minimal context loading).

The full framework spec is at: `~/duki-admin/research/projects/intern-os/`

Follow every step below. Do not skip steps. Confirm each step before moving to the next.

---

## Step 1: Install tick.md CLI

```bash
npm install -g tick-md
tick --version
```

Verify it prints a version number.

---

## Step 2: Create the workspace

```bash
mkdir -p ~/.hermes/workspace/projects/
```

---

## Step 3: Install the intern-os skill

Copy the Hermes adapter skill into the skills directory:

```bash
mkdir -p ~/.hermes/skills/intern-os
cp ~/duki-admin/research/projects/intern-os/adapters/hermes/SKILL.md ~/.hermes/skills/intern-os/SKILL.md
```

Also copy the assets and references so you can access them at runtime:

```bash
cp -r ~/duki-admin/research/projects/intern-os/assets/ ~/.hermes/skills/intern-os/assets/
cp -r ~/duki-admin/research/projects/intern-os/references/ ~/.hermes/skills/intern-os/references/
```

---

## Step 4: Copy WORKSTREAMS.md to the workspace

```bash
cp ~/duki-admin/research/projects/intern-os/assets/WORKSTREAMS.md ~/.hermes/workspace/WORKSTREAMS.md
```

This is the agent runtime guide. Read it — it defines how you operate within workstreams.

---

## Step 5: Create the first project

Use the project template to scaffold:

```bash
cp -r ~/duki-admin/research/projects/intern-os/assets/templates/project/ ~/.hermes/workspace/projects/duki-ops/
```

This creates `PROJECT.md`, `AGENTS.md`, `TICK.md`, `.tick/config.yml`, and `workstreams/`.

Then initialize tick.md and register yourself:

```bash
cd ~/.hermes/workspace/projects/duki-ops
tick init --force
tick agent register @duki --type bot --role engineer
```

> `--force` overwrites the template TICK.md with a properly initialized one. The .tick/config.yml from the template is already correct.

Verify:

```bash
tick status
tick agent list
```

---

## Step 6: Verify the workspace structure

Run `ls -R ~/.hermes/workspace/` and confirm it looks like this:

```
~/.hermes/workspace/
├── WORKSTREAMS.md
└── projects/
    └── duki-ops/
        ├── PROJECT.md
        ├── AGENTS.md
        ├── TICK.md
        ├── .tick/
        │   └── config.yml
        └── workstreams/
```

---

## Step 7: Read the framework

Read these files to understand the full framework you're now operating under:

1. `~/.hermes/workspace/WORKSTREAMS.md` — your runtime operating guide
2. `~/.hermes/skills/intern-os/references/en/FRAMEWORK.md` — architecture spec
3. `~/.hermes/skills/intern-os/references/en/TICK-INTEGRATION.md` — how tick.md works with workstreams
4. `~/.hermes/skills/intern-os/references/en/COMMUNICATION.md` — how Slack/Discord threads map to workstreams

---

## Step 8: Activate your first workstream

Test the full workflow by activating a workstream in the `duki-ops` project:

1. Add a task:
   ```bash
   cd ~/.hermes/workspace/projects/duki-ops
   tick add "Set up internOS framework and verify all layers work" --tag internos-setup --priority high
   ```

2. Create the workstream directory:
   ```bash
   cp -r ~/duki-admin/research/projects/intern-os/assets/templates/workstream/ ~/.hermes/workspace/projects/duki-ops/workstreams/internos-setup/
   mkdir -p ~/.hermes/workspace/projects/duki-ops/workstreams/internos-setup/docs
   ```

3. Fill in BRIEF.md with:
   - What: Set up and verify the internOS Workstreams framework on Duki
   - Problem: Agent needs structured workstream coordination across sessions
   - Who: Mel — to organize Duki's work into trackable workstreams
   - Outcome: A working internOS installation with one verified project and workstream
   - Scope: Framework setup only, no communication platform wiring yet
   - Appetite: 1 session

4. Fill in STATUS.md with the current state

5. Fill in RESOURCES.md with links to the task and directory

6. Claim the task and work it:
   ```bash
   cd ~/.hermes/workspace/projects/duki-ops
   tick claim TASK-001 @duki
   ```

7. When done:
   ```bash
   tick done TASK-001 @duki
   ```

8. Update STATUS.md with what was done

---

## Step 9: Confirm everything works

Run these checks:

```bash
# tick.md is working
cd ~/.hermes/workspace/projects/duki-ops && tick status

# Workspace structure is correct
ls ~/.hermes/workspace/projects/duki-ops/workstreams/internos-setup/

# Skill is installed
ls ~/.hermes/skills/intern-os/SKILL.md

# WORKSTREAMS.md is in place
cat ~/.hermes/workspace/WORKSTREAMS.md | head -5
```

Report the results of each check.

---

## What you now know how to do

After completing setup, you can:

- **Create a new project:** `mkdir projects/[name] && cd projects/[name] && tick init && tick agent register @duki --type bot --role engineer`
- **Add a workstream:** `tick add "Description" --tag ws-name` then scaffold the directory from templates
- **Work a session:** Read BRIEF→STATUS→MEMORY, claim task, do work, update STATUS, done/release task
- **Check status:** `tick status` (project-level) or `tick list --tag ws-name` (workstream-level)

The full reference is in `~/.hermes/skills/intern-os/references/en/PLAYBOOK.md`.
