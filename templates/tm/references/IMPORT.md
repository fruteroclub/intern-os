# Import Protocol — <TM_NAME>

Steps a receiver follows to load this TM into a compatible environment.

1. **Verify integrity before reading anything else:**
   ```bash
   bash scripts/verify_tm.sh
   ```
   Refuse the TM if this exits non-zero. Investigate before proceeding.

2. **Read TM.yml first** — the machine-readable manifest tells you the type, scope, permissions, and return protocol. If `tm_spec_version` is newer than your tooling supports, refuse the TM.

3. **Preserve the payload path shape when importing:**
   ```
   payload/workspaces/<WORKSPACE>/projects/<PROJECT>[/workstreams/<WORKSTREAM>]/
   ```
   Copy or overlay this into the receiving internOS root unchanged. Do not flatten.

4. **Load files in internOS order:**

   For `internOS.project` TMs:
   - `PROJECT.md`
   - `AGENTS.md` (project-level)
   - `POD.md` (if present)
   - `TICK.md`
   - Active workstream's `BRIEF.md`
   - Active workstream's `STATUS.md`
   - Escalate to `MEMORY.md`, `DECISIONS.md`, `STAKEHOLDERS.md`, `RESOURCES.md` as the task requires

   For `internOS.workstream` TMs:
   - Context headers first: `PROJECT.md`, `AGENTS.md`, `POD.md` (read-only — do not modify these)
   - `BRIEF.md` (full)
   - `STATUS.md` (full)
   - Escalate to `MEMORY.md`, `DECISIONS.md`, `STAKEHOLDERS.md`, `RESOURCES.md` as needed

5. **Do not assume access to excluded paths.** If you need something not in the payload, check `REDACTION_REPORT.md` first — the omission is usually deliberate. Ask the TM author rather than fabricating.

6. **Do not write outside `permissions.allowed_writes`.** The boundary is the contract.

7. **Do not vendor or mutate `code/**` from this TM.** Use repository URLs in `RESOURCES.md` when code work is needed; clone the upstream repos separately.

8. **If using a SessionStart hook** (e.g. the Claude Code `intern-os` adapter), set `INTERNOS_WORKSPACE` to point at the workspace root that now contains the imported payload, so resolution works.
