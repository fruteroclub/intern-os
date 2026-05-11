# Isolated-Session Handoff

internOS handoff doctrine for multi-agent operation. Use this when a coordinator delegates work to an isolated specialist (subagent) that does not inherit the parent's transcript or workstream binding.

Spec: [`docs/specs/v0.4.0-isolated-handoff.md`](../../../docs/specs/v0.4.0-isolated-handoff.md)
Schema: [`intern-os/schemas/handoff-v1.yaml`](../../schemas/handoff-v1.yaml)
Verifier: [`intern-os/scripts/verify-handoff.sh`](../../scripts/verify-handoff.sh)

---

## What problem this solves

internOS works well for a single coordinating agent operating inside a thread: the agent resolves the workstream by exact `thread_id` from `BRIEF.md`, loads minimal context, and reconstructs from files when sessions degrade.

It breaks down when the coordinator delegates to an **isolated specialist** — a fresh subagent session (Hermes `delegate_task`, OpenClaw `sessions_spawn`, Claude Code `Agent` tool). The specialist has filesystem access but no inherited binding. Without explicit handoff, the specialist may:

- operate from generic context instead of the active workstream
- fail to load the right files
- broad-scan the workspace
- produce work that's directionally correct but operationally disconnected

The handoff layer fixes this by passing the specialist a **deterministic, file-backed manifest** that names exactly what to load, what to do, and where to write back.

---

## The four invariants

### 1. Deterministic resolution

The specialist verifies the binding before acting. Verification is exact-match only:

- `workstream_path` exists on disk
- `BRIEF.md` exists at `<workstream_path>/BRIEF.md`
- `BRIEF.md`'s `thread_id` exactly equals the manifest's `thread_id` (string equality, no normalization)
- Every path in `load.required` exists

Any failure: stop, return `status: aborted-binding-mismatch` with the failing check name. No fallback, no fuzzy matching, no "closest project."

### 2. Explicit isolation

The specialist reads only files in `load.required` (and optionally `load.optional` if the task warrants). It does not read sibling workstreams, broad-scan the workspace, or infer related files from naming proximity.

Filesystem isolation is **doctrinal, not OS-enforced.** Each harness adapter documents what additional sandboxing it can provide.

### 3. Files are the source of truth

The manifest **points at** files; it does not embed their content. Specialists read `BRIEF.md` and `STATUS.md` from disk after verifying the binding, never from the manifest.

The specialist's output is also a file: the **return artifact** at `<workstream_path>/handoffs/<handoff_id>.md`. The free-text return to the coordinator is a one-line summary plus the artifact path.

### 4. Role separation

Specialists are confined to these write paths:

- `<workstream_path>/handoffs/<handoff_id>.md` (return artifact — required)
- `<workstream_path>/handoffs/<handoff_id>/*` (optional sub-artifacts)
- `<workstream_path>/MEMORY.md` (append-only, bounded per `write_back.also_append`)

Specialists must **not** write to `BRIEF.md`, `STATUS.md`, `DECISIONS.md`, or any file outside the workstream. Reconciliation back into `STATUS.md` / `DECISIONS.md` is the **coordinator's** job after reading the return artifact.

---

## Manifest schema v1

Schema lives at [`intern-os/schemas/handoff-v1.yaml`](../../schemas/handoff-v1.yaml). Template at [`intern-os/assets/templates/handoff/manifest.yml`](../../assets/templates/handoff/manifest.yml).

Required fields:

| Field | Purpose |
|---|---|
| `internos_handoff` | schema version literal (`v1`) |
| `handoff_id` | unique within workstream; date-keyed convention |
| `project`, `workstream`, `workstream_path`, `thread_id` | identity — specialist verifies all four |
| `load.required` | files specialist must read (minimum: `BRIEF.md`, `STATUS.md`) |
| `task.objective`, `task.success_condition`, `task.stop_condition` | what / done-when / abort-when |
| `binding_checks` | ordered list of named checks (v1: 4 named below) |
| `write_back.artifact_path` | path under `handoffs/`; specialist writes return artifact here |
| `write_back.artifact_schema` | required sections in the return artifact |

Optional fields:

| Field | Purpose |
|---|---|
| `role` | descriptive (e.g. `market-research-specialist`) |
| `load.optional` | files specialist may read if task warrants |
| `write_back.also_append` | bounded appends; v1 permits only `MEMORY.md` as target |
| `isolation` | redundant inline reminders for the specialist |
| `hermes:`, `openclaw:`, `claude_code:` | harness-specific extensions |

---

## Verification protocol

The four named binding checks shipped in v1:

| Check | Predicate |
|---|---|
| `workstream_path_exists` | `workstream_path` resolves to a directory |
| `brief_md_exists` | `BRIEF.md` is readable at `<workstream_path>/BRIEF.md` |
| `thread_id_matches` | `BRIEF.md`'s `thread_id` exactly equals manifest's |
| `load_required_paths_exist` | every path in `load.required` resolves |

Run order matters — `workstream_path_exists` first; subsequent checks fail less informatively without it.

Reference implementation: [`intern-os/scripts/verify-handoff.sh`](../../scripts/verify-handoff.sh). POSIX bash, no deps.

```bash
bash intern-os/scripts/verify-handoff.sh <manifest-path>
# Exit 0 — all checks passed
# Exit 3 — a named check failed (failing name printed to stderr)
# Exit 2 — usage / missing manifest / parse error
```

Adapters may reimplement in their host language; semantics must match.

---

## Coordinator behavior

1. **Construct the manifest.** Choose a date-keyed `handoff_id`. Fill required fields. Keep `load.required` minimal — Tier 1 (`BRIEF.md` + `STATUS.md`) by default.
2. **Write the manifest** to `<workstream_path>/handoffs/<handoff_id>.yml`.
3. **Spawn the specialist** via the harness's delegation primitive. Pass the manifest path or content as the harness allows.
4. **Wait for completion.** Specialist returns `{artifact_path, status, summary}`.
5. **Read the return artifact** at `<workstream_path>/<artifact_path>`.
6. **Reconcile:**
   - `status: done` → update `STATUS.md` (new phase / next / blockers), append to `DECISIONS.md` if appropriate.
   - `status: blocked` → capture blocker in `STATUS.md.blockers`, surface to human.
   - `status: aborted-binding-mismatch` → inspect the manifest for the failing check name. This is a real bug (wrong thread_id, missing file, copy-paste error). Fix and re-spawn — do not retry blindly.
7. Optional: append one curated line to `MEMORY.md` describing the handoff outcome.

---

## Specialist behavior

Embedded in the specialist's prompt or instructions:

```
1. Read the manifest at <manifest_path>.
2. Run binding_checks in order. If any fails, write the return artifact
   with status=aborted-binding-mismatch and the failing check name,
   then return.
3. Read load.required files. Optionally read load.optional if needed.
4. Execute the task.objective until either:
   - success_condition is observably true, or
   - a stop_condition fires.
5. Write the return artifact at write_back.artifact_path using the
   schema in write_back.artifact_schema. Set status appropriately.
6. If write_back.also_append is set, append (do not overwrite) to the
   listed target(s), respecting max_lines.
7. Return to the coordinator: {artifact_path, status, one-line summary}.

Do not:
- read sibling workstreams
- modify BRIEF.md, STATUS.md, DECISIONS.md
- write outside <workstream_path>
- broad-scan the workspace
```

---

## Storage layout

```
<workstream_path>/
├── BRIEF.md
├── STATUS.md
├── MEMORY.md
├── DECISIONS.md
├── STAKEHOLDERS.md
├── RESOURCES.md
├── handoffs/                         ← added by v0.4.0
│   ├── <handoff_id>.yml              ← manifest (durable record)
│   ├── <handoff_id>.md               ← return artifact (specialist output)
│   └── <handoff_id>/                 ← optional, multi-file outputs
│       ├── intermediate-1.md
│       └── intermediate-2.md
└── docs/
```

The `handoffs/` directory accumulates the audit trail — every delegation, what was asked, what was returned. Manifests are append-only; specialists must not overwrite or delete.

---

## End-to-end example

See [`examples/isolated-session-handoff.md`](../../../examples/isolated-session-handoff.md) for a concrete walkthrough: coordinator constructs a manifest, spawns a specialist, specialist verifies + executes + writes the artifact, coordinator reconciles.

---

## Per-harness notes

Each adapter `SETUP.md` has a "Isolated-session handoff" section documenting the harness's native delegation mechanism and any harness-specific extensions to the manifest:

- [`adapters/hermes/SETUP.md`](../../../adapters/hermes/SETUP.md) — `delegate_task`, optional `hermes.acp_command` / `hermes.toolsets` extensions
- [`adapters/openclaw/SETUP.md`](../../../adapters/openclaw/SETUP.md) — `sessions_spawn` with isolated runtime, optional attachments
- [`adapters/claude-code/SETUP.md`](../../../adapters/claude-code/SETUP.md) — `Agent` tool with manifest embedded in subagent prompt; `SubagentStop` hook for post-validation

---

## Open questions (deferred)

These are real concerns parked for post-v0.4.0:

- **Concurrent specialists.** Multiple specialists for the same workstream in parallel — race on `MEMORY.md` appends? Locking semantics?
- **Manifest signing.** Optional detached signatures for trust-sensitive deployments.
- **Schema evolution.** v2 path when v1 fields prove insufficient. Specialists reject unknown versions.
- **Cross-workstream handoff.** Tasks that genuinely span two workstreams. Current answer: spawn two specialists. If that becomes painful, formalize.
- **Hooks-driven auto-reconcile.** Could Claude Code's `SessionEnd` hook auto-reconcile artifacts? Defer until usage patterns emerge.
- **Reconciliation flow specifics.** This doc says "coordinator updates STATUS.md after reading the artifact" without templating the how. Coordinator discretion in v0.4.0.

File new issues against the repo if any of these blocks operational use.
