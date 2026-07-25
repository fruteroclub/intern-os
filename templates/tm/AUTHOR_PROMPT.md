# TM Author Prompt

A portable, copy-paste prompt that guides any LLM (Claude, GPT, Gemini, Codex,
OpenClaw, Hermes, …) to author a Transfer Module (TM) Skill for a specific
task/service — without needing the full `intern-os` skill installed on the
authoring side.

The prompt points the model at this repository's `v1.0.0` tag so the
protocol it reads is frozen at the stable release.

---

## How to use

1. Copy the fenced prompt below into your LLM of choice.
2. Fill in the `# Inputs` block at the top.
3. Approve the model's plan (Step 2) before it generates files.
4. Run `bash <TM_NAME>/scripts/verify_tm.sh` after generation.

---

## The prompt

```
You are going to author an internOS Transfer Module (TM) — a portable,
harness-agnostic context capsule packaged as a Skill — for the following
task/service.

# Inputs (fill these in)
- TM_NAME (kebab-case, ends in "-tm"): <e.g. method-lab-engine-delivery-tm>
- TM_TYPE: one of [internOS.project | internOS.workstream | internOS.engagement-delivery]
- WORKSPACE: <e.g. agencia | poktalabs | frutero>
- PROJECT: <e.g. method-lab>
- WORKSTREAM (or "null" if type=project): <e.g. engine-delivery>
- THING (human label): <e.g. "Method Lab engine delivery">
- PURPOSE (one paragraph): what the receiver needs to do with this TM
- SOURCE_PATH on disk: <absolute path to the project/workstream/engagement folder>
- AUTHOR: <name / email / handle>

# Step 1 — Read the protocol (pinned to v1.0.0)
Fetch and read these files in order. Do NOT skip; they define the contract.

1. Spec — rules, boundaries, frontmatter, manifest, lifecycle:
   https://raw.githubusercontent.com/fruteroclub/intern-os/v1.0.0/docs/specs/transfer-modules.md
2. Shared-docs + export rules (what may travel, redaction requirements,
   §6a heavy-asset RESOURCES convention):
   https://raw.githubusercontent.com/fruteroclub/intern-os/v1.0.0/docs/specs/shared-docs-and-tm-export.md
3. Base template (SKILL.md frontmatter + section conventions):
   https://raw.githubusercontent.com/fruteroclub/intern-os/v1.0.0/templates/tm/SKILL.md
4. Base template README (receiver-facing intro):
   https://raw.githubusercontent.com/fruteroclub/intern-os/v1.0.0/templates/tm/README.md
5. References used by every TM:
   - TM.yml manifest:        .../templates/tm/references/TM.yml
   - IMPORT.md:              .../templates/tm/references/IMPORT.md
   - EXPORT_MANIFEST.md:     .../templates/tm/references/EXPORT_MANIFEST.md
   - REDACTION_REPORT.md:    .../templates/tm/references/REDACTION_REPORT.md
   - RETURN.md:              .../templates/tm/references/RETURN.md
   - verify_tm.sh:           .../templates/tm/scripts/verify_tm.sh
6. If TM_TYPE = internOS.engagement-delivery, ALSO read the engagement-delivery
   overlay (adds APPLY.md + apply_to_target.sh, replaces RETURN.md semantics):
   https://raw.githubusercontent.com/fruteroclub/intern-os/v1.0.0/templates/tm/engagement-delivery/SKILL.md
   plus the sibling references/ and scripts/ under that directory.

# Step 2 — Plan before writing
Produce a short plan that lists:
- the canonical_path and payload_path (per spec "Canonical home")
- which files from SOURCE_PATH go into payload/ (apply the type's default
  "includes" + "excludes" lists from the spec)
- any heavy assets that must become POINTERS in RESOURCES.md (§6a) instead
  of bytes in the payload
- secrets / credentials / private state that must be redacted (record in
  REDACTION_REPORT.md)
- the receiver's contribution boundary (what they MAY and MAY NOT touch)

Pause and show me the plan. Do not generate files until I confirm.

# Step 3 — Generate the TM directory
After plan approval, generate the full directory tree at ./<TM_NAME>/ :

  <TM_NAME>/
    SKILL.md                         # entry point, frontmatter-driven
    README.md                        # receiver-facing intro
    references/
      TM.yml                         # machine-readable manifest
      IMPORT.md                      # how the receiver imports
      EXPORT_MANIFEST.md             # what was exported, with hashes
      REDACTION_REPORT.md            # what was checked + omitted
      RETURN.md                      # how to send changes back
                                     #   (for engagement-delivery: replace
                                     #    with APPLY.md + scripts/apply_to_target.sh)
    scripts/
      verify_tm.sh                   # copy verbatim from template
    payload/
      workspaces/<WORKSPACE>/projects/<PROJECT>[/workstreams/<WORKSTREAM>]/...

Rules:
- SKILL.md frontmatter MUST match the spec's "SKILL.md frontmatter" section
  exactly (name, description starting with "Use when …", version, author,
  license, platforms, metadata.hermes, metadata.tm with tm_spec_version: 1.0,
  type, workspace, project, workstream, canonical_path, payload_path,
  created_at as ISO8601).
- The `description` field is what triggers the skill in agent harnesses —
  write it so a receiver LLM can decide whether to load this TM. Lead with
  "Use when …".
- Apply default excludes from the spec (node_modules, .git, secrets, .env*,
  nested code repos, etc.).
- For heavy assets, add a POINTERS table to a workstream/project RESOURCES.md
  (per §6a) instead of copying bytes.
- Do not invent fields. If the spec doesn't define it, leave it out.

# Step 4 — Self-verify
After generation:
1. Run `bash <TM_NAME>/scripts/verify_tm.sh` and show the output. It must
   print "TM verification OK".
2. Show me the SKILL.md frontmatter and the TM.yml so I can spot-check
   boundary, redactions, and includes/excludes.
3. List any open questions or judgment calls you made (e.g. files you
   weren't sure whether to include).

# Constraints
- Pin all reads to tag v1.0.0 — do NOT follow the main branch, which may
  shift.
- The full intern-os skill is NOT installed on the receiver. Everything
  the receiver needs to act must live inside the TM directory itself.
- If the spec and this prompt disagree, the spec wins — quote the section
  and flag the conflict.
```

---

## Notes

- **Engagement-delivery TMs** (TM applies a diff to a target repo — e.g. the
  `method-lab-engine-delivery-tm`): make sure the model picks up the
  `templates/tm/engagement-delivery/` overlay. Its `APPLY.md` +
  `apply_to_target.sh` replace the base `RETURN.md` flow.
- **Pin to the tag, not the branch.** `main` is mutable; `v1.0.0` is frozen.
  When the next stable release ships, update the pinned URLs here in a
  single sweep.
