# Git tracking for internOS workspaces

*Status: convention proposal. Not yet enforced by tooling.*

## Problem

internOS workstreams live at `<workspace>/projects/<project>/workstreams/<name>/` and accumulate state over time — BRIEF.md, STATUS.md, MEMORY.md, DECISIONS.md, TICK.md, etc. This state is operationally valuable, but the framework today treats it as "files on disk" with no version history. Meanwhile, each project also contains real code that must be tracked in its own repo (often multiple repos per project — landing page, API, SDK, etc.).

The question is how to introduce git tracking for internOS state without colliding with code repos that are already (or will be) git-tracked at deeper paths.

## Model: three-tier containment mirroring the GitHub org graph

The filesystem hierarchy mirrors how teams organize repos under a GitHub organization:

| Tier | Path | Maps to | What it tracks |
| --- | --- | --- | --- |
| Workspace | `<workspace>/` | A GitHub organization | Org-level internOS state: README, workspace-level AGENTS.md, `projects/REGISTRY.md`, shared docs |
| Project | `<workspace>/projects/<project>/` | A logical product/initiative inside the org | Project-level internOS state: PROJECT.md, TICK.md, AGENTS.md, all `workstreams/<name>/*.md` |
| Code | `<workspace>/projects/<project>/<repo>/` | An individual code repo on GitHub | Source code, the actual product (landing, studio, skills, etc.) |

Each tier is a **separate git repo**. They nest on disk because internOS uses filesystem containment to express conceptual containment that GitHub orgs only express in their admin layer.

### Worked example — Pokta Labs

```
workspaces/poktalabs/                         clone of poktalabs/poktalabs-os         (workspace repo)
├── .git/
├── README.md, AGENTS.md, docs/                 ← tracked here
└── projects/
    ├── REGISTRY.md                              ← tracked here
    └── godinez-ai/                           clone of poktalabs/godinez-ai-os        (project repo)
        ├── .git/
        ├── PROJECT.md, TICK.md, AGENTS.md
        ├── workstreams/<name>/*.md              ← tracked here
        ├── landing/   .git/                  clone of poktalabs/godinez-ai-landing   (code repo)
        ├── studio/    .git/                  clone of poktalabs/godinez-ai-studio    (code repo)
        └── skills/    .git/                  clone of poktalabs/godinez-ai-skills    (code repo)
```

## The clash, and why nested repos still work here

Naïvely, nested git repos are a footgun: the parent repo "sees" the child's working tree, which leads to ambiguous commits, surprise stashes, and submodule-style headaches.

This convention sidesteps the clash by making each parent repo's `.gitignore` an **allowlist**, not a denylist. The parent ignores everything by default and only re-includes the specific internOS file shapes it owns. Nested child directories — whose contents are themselves repos — are excluded by the catch-all and never visible to the parent.

This means:

- The workspace repo never sees inside `projects/<project>/`. The project repo is opaque.
- The project repo never sees inside its code subdirectories. The code repos are opaque.
- Each repo's diffs are clean and bounded to that tier's files.
- `git status` at any level shows only that level's changes — no spurious "untracked files" from below.

## Canonical .gitignore templates

The framework ships allowlist templates that projects should copy as their starting point:

- `templates/git/workspace.gitignore` — workspace-level allowlist
- `templates/git/project.gitignore` — project-level allowlist (including workstream files)

Copy on `git init`:

```bash
# Workspace-level
cp <intern-os-checkout>/templates/git/workspace.gitignore <workspace>/.gitignore

# Project-level
cp <intern-os-checkout>/templates/git/project.gitignore <workspace>/projects/<project>/.gitignore
```

Symlinking instead of copying keeps the allowlist in sync with framework updates, at the cost of making the project repo's `.gitignore` non-standalone (a fresh clone of the project repo needs the framework installed to resolve the symlink). Copy is the safer default.

## Naming convention for the os-repos

`<thing>-os` (e.g. `poktalabs-os`, `godinez-ai-os`) keeps internOS-state repos visually distinct from product repos in the GitHub org's repo list. Alternatives: `<thing>-internos`, `<thing>-workstreams`. Pick a single suffix per org and stick with it.

## Migrating an existing project

For a project that already has code subdirectories with their own `.git`:

1. `cd <workspace>/projects/<project>`
2. `cp <intern-os-checkout>/templates/git/project.gitignore .gitignore`
3. `git init`
4. `git add .gitignore PROJECT.md TICK.md AGENTS.md workstreams/`
5. `git commit -m "chore: initialize internOS state tracking"`
6. Create the matching empty repo on GitHub (e.g. `<org>/<project>-os`).
7. `git remote add origin git@github.com:<org>/<project>-os.git && git push -u origin main`

The code subdirectories are unaffected — their `.git/` and remote bindings remain. The project repo simply cannot see them.

## Tradeoffs

**Maintenance cost.** Every new internOS file shape (e.g. if v0.5 adds `RISKS.md`) must be added to the allowlist, or it won't be tracked. The templates in this directory are the single source of truth — update them when the framework evolves, then projects sync.

**Multiple `.git` directories on disk.** Three or more `.git` dirs per project tree (workspace, project, each code repo). `find` / globbing tools see them all. Some IDEs (notably JetBrains) get confused; VS Code and Cursor handle nested repos gracefully when the outer repo never touches the inner working trees, which the allowlist guarantees.

**The workspace repo can outgrow its mandate.** It's tempting to start committing project-level files at the workspace level "just for visibility." Don't. If a fact belongs to a project, it lives in the project repo. The workspace repo is for genuinely org-wide state (org-level AGENTS.md, the REGISTRY, cross-project docs).

**Fresh-clone bootstrap.** A new contributor cloning `<org>-os` gets the org's internOS state but not the project repos inside it. Bootstrapping a working tree requires cloning each project repo separately into the right `projects/<project>/` slot. A future `oficina bootstrap` / `intern-os bootstrap` script can automate this from `projects/REGISTRY.md`.

## Open questions

- **Whose responsibility is the workspace-level AGENTS.md vs. CLAUDE.md?** Currently the Claude Code adapter recommends a CLAUDE.md pointer to AGENTS.md. The workspace repo should track both, with CLAUDE.md being the lightweight pointer file.
- **Should `tmp/`, `node_modules/`, and other transient artifacts be added to the templates as belt-and-suspenders?** Allowlist style makes this unnecessary (anything not explicitly re-included is ignored), but explicit `node_modules/` lines reduce confusion for newcomers reading the file.
- **Does `sync-check.sh` need to learn about git tracking?** Probably yes — a workstream whose BRIEF.md isn't committed is implicitly different from one that is. INFO-level note when the project repo has uncommitted internOS files seems right.
