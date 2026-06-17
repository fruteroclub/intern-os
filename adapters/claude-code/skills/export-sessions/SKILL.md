---
name: export-sessions
repo: https://github.com/fruteroclub/intern-os
metadata:
  version: 0.1.0
description: >-
  Export a whole internOS project's tracking state to migrate it to another
  internOS-native host (same setup). Use when the user says "export sessions",
  "export the project", "move this project to another VPS/machine", "migrate the
  workstream", "back up everything that tracks this project", or wants the session
  history + memories portable. Bundles the four stores that track a project —
  internOS repos, Claude Code sessions/memories, gstack artifacts, and gbrain
  memory — into one encrypted archive, then guides transfer + import on the
  target. The deterministic engine is scripts/export-sessions.sh +
  import-sessions.sh; this skill is the judgment layer (resolve the project,
  decide PHI/encryption, pre-flight pushes, drive the migration).
---

# export-sessions — whole-project context migration

internOS already exports *workstream-scoped* doc capsules (Transfer Modules). This
is the broader move: migrate an **entire project's tracking state** to another host
running the same internOS setup (gbrain + gstack + Claude Code). It is NOT a TM —
it carries session history and agent memory, which TMs deliberately don't.

The engine is two scripts in the claude-code adapter:
`scripts/export-sessions.sh` (source host) and `scripts/import-sessions.sh` (target
host). This skill adds the judgment those scripts can't: what to migrate, how to
handle PHI, and what to verify. Work the steps in order; skip what doesn't apply
and say why.

## The four stores it moves

| Store | Location | How it travels |
|------|----------|----------------|
| internOS repo(s) | `<project>/` (+ gitignored `journals/`) | git bundle (full history, incl. unpushed) |
| Code subrepos | `<project>/code/*/` | recorded → cloned from their remotes on the target (not bundled) |
| Claude Code | `~/.claude/projects/<slug>/` — transcripts + `memory/` | copied; slug remapped if the target path differs |
| gstack artifacts | `~/.gstack/projects/*<name>*/` | copied |
| gbrain memory | brain DB pages under `<workspace-rel-path>/…` | exported to markdown, re-imported + re-embedded on target |

## Step 0 — Resolve the project

Confirm the project to export: a dir with `PROJECT.md`. Default to the one inferred
from the cwd (walk up to the `PROJECT.md`). Echo the resolved path back to the user.
If ambiguous, ask.

## Step 1 — Pre-flight (the judgment)

1. **Push the code subrepos first.** Subrepos travel as *clone-from-remote*, not
   bundles — so unpushed commits in `code/*/` would be LOST. The export script
   warns (`⚠ <repo> has N unpushed commit(s)`); surface that to the user and have
   them push before exporting. (The internOS project repo itself is bundled, so its
   unpushed commits are safe.)
2. **PHI / secrets decision.** Session transcripts can contain PHI or pasted
   secrets; `.env*` files are gitignored and NOT in the bundle (must be
   re-provisioned on the target). Default and recommendation: **encrypt the bundle**
   (the script uses gpg AES-256). Only skip encryption (`--no-encrypt`) if the
   transfer channel is fully trusted and the user accepts it. If the project has no
   PHI/secret exposure at all, encryption is still cheap insurance.
3. **Target sanity.** Confirm the target host runs the same internOS setup (gbrain
   configured with embeddings, gstack installed, Claude Code, `~/workspaces` layout).
   Same path → slugs match automatically; different path → the importer remaps the
   Claude slug, and gbrain/gstack slugs derive from git remotes (which match).

## Step 2 — Export (source host)

Run the engine. **gpg prompts for a passphrase interactively**, so if you (the agent)
can't prompt, tell the user to run it in their terminal with the `!` prefix:

```
! bash <adapter>/scripts/export-sessions.sh <project-path> --out ~/Desktop
```

Flags: `--out <dir>` (where to write the bundle), `--no-encrypt` (skip gpg — only if
decided in Step 1). Output: `<project>-context-<ts>.tar.gz.gpg`. The script prints a
per-store summary; relay it. Carry the passphrase to the target **separately** from
the bundle.

## Step 3 — Transfer

`scp` (or any trusted channel) the bundle to the target host. The bundle is
self-contained except for code subrepos (cloned from remotes) and secrets.

## Step 4 — Import (target host)

On the target:

```
bash <adapter>/scripts/import-sessions.sh <bundle>.tar.gz.gpg [--project-path <path>] [--dry-run]
```

- `--dry-run` first is recommended — it prints every planned action (repo restores,
  slug remap, file copies, `gbrain import`) without writing.
- It restores the internOS repo from the bundle, clones the code subrepos from their
  remotes, copies Claude/gstack data (remapping the Claude slug if the path differs),
  and runs `gbrain import` (pages re-embed on the target's brain).

Then, on the target, complete the manual steps the script lists:
- **Re-provision secrets** not in the bundle: `code/*/.env.local` (API keys, DB URLs).
- **Verify:** `gbrain query "<project>"`, `ls ~/.claude/projects/<slug>`, `git -C <project> log --oneline -1`.
- `cd` into the workstream so the `intern-os` skill auto-loads `STATUS`/`BRIEF`.

## Notes

- **Reusable:** project-agnostic — pass any internOS project path.
- **Not a TM:** if the user only wants a portable, scoped doc capsule (for handoff to
  a client/agent, not a full host migration), use the Transfer Module flow instead.
- **Idempotent-ish:** import skips repos that already exist at the target path; it
  won't clobber an existing checkout.
