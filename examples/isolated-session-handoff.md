# Example: Isolated-Session Handoff

Concrete end-to-end walkthrough of a coordinator delegating to a specialist via the v0.4.0 handoff layer.

**Scenario:** the main coordinating agent is working in the `amber` project's `market-validation` workstream. The coordinator has collected discovery-call notes and wants a specialist to synthesize market sizing from them. The coordinator stays focused on the broader workstream; the specialist runs isolated.

---

## Starting state

```
$INTERNOS_WORKSPACE/projects/amber/
├── PROJECT.md
├── AGENTS.md
├── TICK.md
└── workstreams/
    └── market-validation/
        ├── BRIEF.md              ← thread_id: claude-code:projects/amber/workstreams/market-validation
        ├── STATUS.md
        ├── MEMORY.md
        ├── DECISIONS.md
        ├── STAKEHOLDERS.md
        ├── RESOURCES.md
        └── docs/
            ├── 2026-04-22-discovery-call-acme.md
            ├── 2026-04-25-discovery-call-globex.md
            └── 2026-04-28-discovery-call-initech.md
```

`BRIEF.md` contains (relevant line):

```
thread_id: claude-code:projects/amber/workstreams/market-validation
```

---

## Step 1 — Coordinator constructs the manifest

The coordinator writes `workstreams/market-validation/handoffs/2026-05-11-1430-market-sizing.yml`:

```yaml
internos_handoff: v1

handoff_id: 2026-05-11-1430-market-sizing
project: amber
workstream: market-validation
workstream_path: /Users/mel/workspace/projects/amber/workstreams/market-validation
thread_id: claude-code:projects/amber/workstreams/market-validation

role: market-research-specialist

load:
  required:
    - BRIEF.md
    - STATUS.md
  optional:
    - docs/2026-04-22-discovery-call-acme.md
    - docs/2026-04-25-discovery-call-globex.md
    - docs/2026-04-28-discovery-call-initech.md

task:
  objective: |
    Synthesize the market sizing implied by the three discovery call notes
    in load.optional. Identify the 3 most defensible wedges given current
    scope. Quantify TAM/SAM where the calls give enough signal; explicitly
    note where they don't.
  success_condition: |
    Return artifact exists at write_back.artifact_path with all 5 sections
    populated, including at least 3 named wedges with rationale.
  stop_condition:
    - success condition met
    - blocked by a question only the human can answer (record and stop)
    - binding_check fails (return aborted-binding-mismatch)

binding_checks:
  - workstream_path_exists
  - brief_md_exists
  - thread_id_matches
  - load_required_paths_exist

write_back:
  artifact_path: handoffs/2026-05-11-1430-market-sizing.md
  artifact_schema:
    - objective
    - work
    - findings
    - open-questions
    - status
  also_append:
    - target: MEMORY.md
      max_lines: 3

isolation:
  - do not read sibling workstreams
  - do not modify files outside workstream_path
  - do not modify BRIEF.md, STATUS.md, or DECISIONS.md
```

---

## Step 2 — Coordinator spawns the specialist

Harness-specific. For Claude Code:

```
[Agent tool invocation]
subagent_type: general-purpose
prompt: |
  You are an isolated specialist receiving a handoff manifest. Follow the
  intern-os specialist protocol: verify binding, load, execute, write
  artifact, return.

  Manifest path: /Users/mel/workspace/projects/amber/workstreams/market-validation/handoffs/2026-05-11-1430-market-sizing.yml

  Manifest content:
  ```yaml
  <full manifest YAML embedded here>
  ```

  Run binding verification first:
    bash ~/.claude/skills/intern-os/scripts/verify-handoff.sh <manifest-path>

  Exit 3 → write the artifact with status=aborted-binding-mismatch + the
  failing check name, then return. No fallback.

  Otherwise: load load.required and load.optional, execute task.objective,
  write the return artifact per write_back, then return one line:
  "<artifact_path> | <status> | <one-line summary>".
```

For Hermes, the same content goes into `delegate_task.context`. For OpenClaw, `sessions_spawn` with the manifest path as an attachment.

---

## Step 3 — Specialist verifies

The specialist runs:

```bash
bash ~/.claude/skills/intern-os/scripts/verify-handoff.sh \
  /Users/mel/workspace/projects/amber/workstreams/market-validation/handoffs/2026-05-11-1430-market-sizing.yml
```

Output:

```
OK: all binding_checks passed for /Users/mel/workspace/projects/amber/workstreams/market-validation/handoffs/2026-05-11-1430-market-sizing.yml
```

Exit 0 → proceed.

---

## Step 4 — Specialist executes

The specialist reads `BRIEF.md` and `STATUS.md`. The task requires the discovery-call notes, so it also reads the three files in `load.optional`. It does **not** read `DECISIONS.md`, `STAKEHOLDERS.md`, `RESOURCES.md`, or anything outside `workstream_path`.

The specialist synthesizes the market sizing.

---

## Step 5 — Specialist writes the return artifact

The specialist writes `workstreams/market-validation/handoffs/2026-05-11-1430-market-sizing.md`:

```markdown
## objective

Synthesize market sizing from the three Acme/Globex/Initech discovery calls;
identify 3 most defensible wedges.

## work

Read three discovery-call notes (Acme 2026-04-22, Globex 2026-04-25, Initech
2026-04-28). Extracted explicit market signals: budget ranges, decision
timelines, existing tooling, mentioned competitors. Cross-referenced for
overlap and contradiction.

## findings

### Defensible wedges (ordered by signal strength)

1. **Mid-market ops automation** — Acme and Initech both surfaced this as
   a budget-approved priority in next 2 quarters. Globex mentioned but not
   approved.

2. **Compliance reporting for regulated industries** — Initech named two
   specific competitors; Acme implied dissatisfaction with their incumbent.
   Strongest competitive opening.

3. **Cross-team data reconciliation** — All three surfaced this as pain.
   Lowest budget signal but highest pain consistency.

### Market sizing

- TAM (mid-market, 50-500 employees, US): ~$2.4B annualized based on
  three-data-point extrapolation. **Wide error bars** — three calls is
  insufficient for confident sizing.
- SAM (the three named wedges): ~$420M annualized.
- SOM: not estimable from current data.

## open-questions

- Pricing model — none of the three calls explicitly named tolerable price
  points. Need targeted follow-up.
- Globex's "next quarter" timeline — unclear if budget is actually
  approved or aspirational.

## status

done
```

The specialist also appends to `MEMORY.md` (per `write_back.also_append`, max 3 lines):

```
- 2026-05-11: Three discovery calls synthesized. Three wedges identified;
  mid-market ops automation strongest. TAM ~$2.4B w/ wide error bars.
  Pricing data still missing.
```

---

## Step 6 — Specialist returns to coordinator

```
handoffs/2026-05-11-1430-market-sizing.md | done | 3 wedges identified; pricing data still missing
```

---

## Step 7 — Coordinator reconciles

The coordinator reads the return artifact. Status is `done`. The coordinator:

1. Updates `STATUS.md`:
   ```
   Phase: synthesis
   Next: 1-on-1 follow-up calls on pricing — Acme + Initech first
   Owner: mel
   Blockers: none
   Updated: 2026-05-11
   ```

2. Appends to `DECISIONS.md`:
   ```
   ## 2026-05-11 — Three primary wedges identified

   - decision: Pursue mid-market ops automation as primary wedge; compliance
     reporting as secondary; cross-team reconciliation as parking-lot.
   - rationale: See handoffs/2026-05-11-1430-market-sizing.md findings —
     budget signal strongest for #1, competitive opening clearest for #2.
   - impact: Reframes next-quarter roadmap around wedge #1; pricing
     conversations become next priority.
   - status: accepted
   ```

3. Optionally appends one line to its own `MEMORY.md` (separate from the specialist's append):
   ```
   - 2026-05-11: Reconciled market-sizing handoff. Wedges + decision locked.
   ```

---

## Resulting state

```
workstreams/market-validation/
├── BRIEF.md                            ← unchanged
├── STATUS.md                           ← updated by coordinator
├── MEMORY.md                           ← specialist + coordinator each appended
├── DECISIONS.md                        ← coordinator added new entry
├── handoffs/
│   ├── 2026-05-11-1430-market-sizing.yml   ← durable manifest record
│   └── 2026-05-11-1430-market-sizing.md    ← specialist's return artifact
└── docs/
    └── (unchanged)
```

The handoffs/ directory now holds the audit trail. Anyone reading later can see: what was asked (the .yml manifest), what was produced (the .md artifact), and how it affected workstream state (DECISIONS.md + STATUS.md + MEMORY.md changes around the same date).

---

## What would have gone wrong without the manifest

Without an explicit handoff manifest, the coordinator would have either:

- **Dumped context into the spawn prompt** — the specialist sees a wall of text, doesn't know what's authoritative, may infer wrong workstream
- **Trusted cwd inheritance alone** — the specialist might be in the right directory but lacks the `thread_id` to verify
- **Skipped verification** — the specialist starts work, then discovers half-way through the wrong workstream was implied

The manifest collapses all of that into one deterministic protocol: read this file, verify these checks, load only these files, write to only this path, return.

---

## What would have gone wrong without the verifier

If the coordinator had typo'd the `thread_id` in the manifest:

```bash
bash ~/.claude/skills/intern-os/scripts/verify-handoff.sh <manifest>
# FAIL: thread_id_matches — manifest='claude-code:projects/amber/workstreams/marketvalidation' BRIEF.md='claude-code:projects/amber/workstreams/market-validation'
# exit=3
```

The specialist writes the artifact with `status: aborted-binding-mismatch` and stops. The coordinator inspects, sees the typo, fixes the manifest, re-spawns. Zero wasted task execution.

---

## See also

- Spec: [`docs/specs/v0.4.0-isolated-handoff.md`](../docs/specs/v0.4.0-isolated-handoff.md)
- Reference: [`intern-os/references/en/ISOLATED-HANDOFF.md`](../intern-os/references/en/ISOLATED-HANDOFF.md)
- Schema: [`intern-os/schemas/handoff-v1.yaml`](../intern-os/schemas/handoff-v1.yaml)
- Template: [`intern-os/assets/templates/handoff/manifest.yml`](../intern-os/assets/templates/handoff/manifest.yml)
- Verifier: [`intern-os/scripts/verify-handoff.sh`](../intern-os/scripts/verify-handoff.sh)
